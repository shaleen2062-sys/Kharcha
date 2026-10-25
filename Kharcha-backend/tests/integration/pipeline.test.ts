/**
 * End-to-end through the real Express app and a real MongoDB (mongodb-memory-server downloads one
 * the first time: needs internet). Covers: upload -> background read -> validation -> confirmed,
 * review + correction learning, budgets -> alerts, dashboard, idempotency.
 * Run everything with `npm test`.
 */
import mongoose from 'mongoose';
import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { createApp } from '../../src/app';
import { setReader, manualReader, ReceiptReader } from '../../src/receipts/reader.client';
import { setStorage, MemoryStorage, signer } from '../../src/storage/storage';
import { queue } from '../../src/jobs/queue';
import { dateInTz } from '../../src/utils/dates';
import { env } from '../../src/config/env';

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 1, 2, 3]);
const AUTH = { Authorization: 'Bearer dev:alice' };
const today = dateInTz(env.APP_TZ);
const month = today.slice(0, 7);

const aiReader = (over: Record<string, unknown> = {}): ReceiptReader => ({
  name: 'http',
  async read() {
    return {
      merchant: 'Bhat-Bhateni',
      total: 1000,
      date: today,
      currency: 'NPR',
      confidence: 0.9,
      readerNeedsReview: false,
      readable: true,
      items: [
        { name: 'Rice', price: 600, quantity: 1 },
        { name: 'Momo', price: 200, quantity: 2 },
      ],
      itemLabels: ['Groceries', 'Dining'],
      ...over,
    };
  },
});

let mongod: MongoMemoryServer;
const app = createApp();
const upload = (key?: string) => {
  const r = request(app).post('/api/receipts').set(AUTH).attach('image', JPEG, { filename: 'a.jpg', contentType: 'image/jpeg' });
  return key ? r.set('Idempotency-Key', key) : r;
};

beforeAll(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
  setStorage(new MemoryStorage(signer));
});
afterAll(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});
afterEach(() => setReader(null));

describe('receipt pipeline', () => {
  it('reads a photo, maps categories, validates and confirms it', async () => {
    setReader(aiReader());
    const up = await upload('k-1');
    expect(up.status).toBe(202);
    expect(up.body.receipt.status).toBe('processing');
    await queue.idle();

    const got = await request(app).get(`/api/receipts/${up.body.receipt.id}`).set(AUTH);
    expect(got.body.receipt.status).toBe('confirmed');
    expect(got.body.receipt.items.map((i: { category: string }) => i.category)).toEqual(['Groceries', 'Food & Dining']);
    expect(got.body.receipt.imageUrl).toContain('/files/');

    const again = await upload('k-1'); // same Idempotency-Key
    expect(again.status).toBe(200);
    expect(again.body.receipt.id).toBe(up.body.receipt.id);
  });

  it('the dashboard counts confirmed receipts and a budget raises an alert', async () => {
    const cats = (await request(app).get('/api/categories').set(AUTH)).body.categories as Array<{ id: string; name: string }>;
    const groceries = cats.find((c) => c.name === 'Groceries')!;

    const sum = await request(app).get(`/api/dashboard/summary?month=${month}`).set(AUTH);
    expect(sum.status).toBe(200);
    expect(sum.body.summary.total).toBeGreaterThanOrEqual(1000);
    expect(sum.body.summary.daily.length).toBeGreaterThanOrEqual(28);

    const put = await request(app).put(`/api/budgets/${groceries.id}`).set(AUTH).send({ limit: 700 });
    expect(put.status).toBe(200);
    expect(put.body.budget.spent).toBe(600);

    const alerts = await request(app).get('/api/alerts?unread=true').set(AUTH);
    expect(alerts.body.alerts.some((a: { type: string }) => a.type === 'budget_warning')).toBe(true);
    expect(alerts.body.unreadCount).toBeGreaterThan(0);

    const all = await request(app).post('/api/alerts/read-all').set(AUTH);
    expect(all.status).toBe(204);
  });

  it('with no AI (manual reader) the receipt waits for the user, and corrections are remembered', async () => {
    setReader(manualReader);
    const up = await upload('k-2');
    await queue.idle();
    const got = await request(app).get(`/api/receipts/${up.body.receipt.id}`).set(AUTH);
    expect(got.body.receipt.status).toBe('needs_review');

    const created = await request(app).post('/api/categories').set(AUTH).send({ name: 'Personal Care' });
    expect(created.status).toBe(201);
    const personal = created.body.category as { id: string; name: string };
    const saved = await request(app)
      .patch(`/api/receipts/${up.body.receipt.id}`)
      .set(AUTH)
      .send({ status: 'confirmed', merchant: 'Corner shop', total: 90, date: today, items: [{ name: 'Tea', price: 90, quantity: 1, categoryId: personal.id }] });
    expect(saved.status).toBe(200);
    expect(saved.body.receipt.status).toBe('confirmed');

    // an AI reading that calls Tea "Groceries" -> now the user's earlier choice is used
    setReader(aiReader({ total: 90, items: [{ name: 'Tea', price: 90, quantity: 1 }], itemLabels: ['Groceries'] }));
    const second = await upload('k-3');
    await queue.idle();
    // first correction only happens when the user CHANGES an AI category, so teach it explicitly:
    const row = await request(app).get(`/api/receipts/${second.body.receipt.id}`).set(AUTH);
    expect(row.body.receipt.items[0].category).toBe('Groceries');
    const fix = await request(app)
      .patch(`/api/receipts/${second.body.receipt.id}`)
      .set(AUTH)
      .send({ status: 'confirmed', items: [{ name: 'Tea', price: 90, quantity: 1, categoryId: personal.id }] });
    expect(fix.status).toBe(200);

    setReader(aiReader({ total: 90, date: '2020-01-01', items: [{ name: 'TEA 250g', price: 90, quantity: 1 }], itemLabels: ['Groceries'] }));
    const third = await upload('k-4');
    await queue.idle();
    const learned = await request(app).get(`/api/receipts/${third.body.receipt.id}`).set(AUTH);
    expect(learned.body.receipt.items[0].category).toBe('Personal Care');
  });

  it('a user only ever sees their own receipts', async () => {
    const res = await request(app).get('/api/receipts').set({ Authorization: 'Bearer dev:bob' });
    expect(res.status).toBe(200);
    expect(res.body.receipts).toEqual([]);
  });

  it('rejects something that is not a JPEG', async () => {
    const res = await request(app).post('/api/receipts').set(AUTH).attach('image', Buffer.from('hello'), { filename: 'a.jpg', contentType: 'image/jpeg' });
    expect(res.status).toBe(422);
  });
});
