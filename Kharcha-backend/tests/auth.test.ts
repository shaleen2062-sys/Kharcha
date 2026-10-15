import request from 'supertest';
import { createApp } from '../src/app';
import { connectDB } from '../src/config/db';

const app = createApp();

beforeAll(async () => {
  await connectDB();
});

describe('auth + users', () => {
  it('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok', env: 'test' });
  });

  it('GET /users/me without token -> 401', async () => {
    const res = await request(app).get('/users/me');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('GET /users/me with malformed Bearer -> 401', async () => {
    const res = await request(app)
      .get('/users/me')
      .set('Authorization', 'Bearer notdev');
    expect(res.status).toBe(401);
  });

  it('GET /users/me with dev token creates user', async () => {
    const res = await request(app)
      .get('/users/me')
      .set('Authorization', 'Bearer dev:testuser1');
    expect(res.status).toBe(200);
    expect(res.body.user.uid).toBe('testuser1');
    expect(res.body.user.id).toBeDefined();
    expect(res.body.user._id).toBeUndefined();
    expect(res.body.user.__v).toBeUndefined();
    expect(res.body.user.deletedAt).toBeUndefined();
  });

  it('same dev token returns the same user (idempotent)', async () => {
    const a = await request(app).get('/users/me').set('Authorization', 'Bearer dev:testuser1');
    const b = await request(app).get('/users/me').set('Authorization', 'Bearer dev:testuser1');
    expect(a.body.user.id).toBe(b.body.user.id);
  });

  it('different dev tokens -> different users (isolation)', async () => {
    const a = await request(app).get('/users/me').set('Authorization', 'Bearer dev:alice');
    const b = await request(app).get('/users/me').set('Authorization', 'Bearer dev:bob');
    expect(a.body.user.id).not.toBe(b.body.user.id);
  });

  it('seeds 13 categories on first login', async () => {
    const res = await request(app)
      .get('/categories')
      .set('Authorization', 'Bearer dev:testuser1');
    expect(res.status).toBe(200);
    expect(res.body.categories).toHaveLength(13);
    const fallback = res.body.categories.find((c: { isFallback: boolean }) => c.isFallback);
    expect(fallback).toBeDefined();
    expect(fallback.name).toBe('Uncategorized');
  });

  it('user A cannot see user B categories', async () => {
    await request(app)
      .post('/categories')
      .set('Authorization', 'Bearer dev:alice')
      .send({ name: 'Alice Custom' });

    const bobCats = await request(app)
      .get('/categories')
      .set('Authorization', 'Bearer dev:bob');
    const names = bobCats.body.categories.map((c: { name: string }) => c.name);
    expect(names).not.toContain('Alice Custom');
  });

  it('PATCH /users/me updates profile fields', async () => {
    await request(app).get('/users/me').set('Authorization', 'Bearer dev:testuser1');

    const res = await request(app)
      .patch('/users/me')
      .set('Authorization', 'Bearer dev:testuser1')
      .send({ name: 'Test User', currency: 'USD', aiEnabled: false });

    expect(res.status).toBe(200);
    expect(res.body.user.name).toBe('Test User');
    expect(res.body.user.currency).toBe('USD');
    expect(res.body.user.aiEnabled).toBe(false);
  });

  it('PATCH /users/me rejects invalid currency', async () => {
    await request(app).get('/users/me').set('Authorization', 'Bearer dev:testuser1');

    const res = await request(app)
      .patch('/users/me')
      .set('Authorization', 'Bearer dev:testuser1')
      .send({ currency: 'XYZ' });

    expect(res.status).toBe(400);
  });

  it('POST /categories creates a new category', async () => {
    const res = await request(app)
      .post('/categories')
      .set('Authorization', 'Bearer dev:testuser1')
      .send({ name: 'Pet Care', icon: 'paw', color: '#FF00FF' });

    expect(res.status).toBe(201);
    expect(res.body.category.name).toBe('Pet Care');
  });

  it('POST /categories with existing name returns existing', async () => {
    const first = await request(app)
      .post('/categories')
      .set('Authorization', 'Bearer dev:testuser1')
      .send({ name: 'Coffee' });

    const second = await request(app)
      .post('/categories')
      .set('Authorization', 'Bearer dev:testuser1')
      .send({ name: 'coffee' });

    expect(first.body.category.id).toBe(second.body.category.id);
  });

  it('cannot delete the fallback category', async () => {
    const cats = await request(app)
      .get('/categories')
      .set('Authorization', 'Bearer dev:testuser1');
    const fallback = cats.body.categories.find((c: { isFallback: boolean }) => c.isFallback);

    const res = await request(app)
      .delete(`/categories/${fallback.id}`)
      .set('Authorization', 'Bearer dev:testuser1');

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/fallback/i);
  });
});