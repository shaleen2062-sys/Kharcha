import { normalizeReading, createHttpReader, manualReader } from '../../src/receipts/reader.client';
import { categoryNameFor } from '../../src/categories/readerCategories';
import { correctionKey } from '../../src/corrections/corrections.service';

describe('reader client', () => {
  it('normalizes what the Python reader sends', () => {
    const r = normalizeReading({
      merchant: ' Bhat-Bhateni ',
      date: '2026-10-03',
      total: 1130,
      confidence: 0.82,
      confidence_reason: 'items add up to the total',
      needs_review: false,
      items: [
        { name: 'Rice', qty: 2, price: 1000, category: 'Groceries' },
        { name: 'Broken', price: 'x' },
        { name: 'Momo', price: 130, category: 'Dining' },
      ],
    });
    expect(r.merchant).toBe('Bhat-Bhateni');
    expect(r.items).toEqual([
      { name: 'Rice', price: 500, quantity: 2 },
      { name: 'Momo', price: 130, quantity: 1 },
    ]);
    expect(r.itemLabels).toEqual(['Groceries', 'Dining']);
    expect(r.confidence).toBe(0.82);
    expect(r.confidenceReason).toBe('items add up to the total');
    expect(r.readerNeedsReview).toBe(false);
  });

  it('survives garbage', () => {
    const r = normalizeReading(null);
    expect(r.items).toEqual([]);
    expect(r.total).toBeNull();
    expect(r.readable).toBe(true);
  });

  it('keeps reader line totals aligned with the printed total', () => {
    const lineTotals = normalizeReading({
      total: 860,
      items: [
        { name: 'A', price: 400, qty: 2 },
        { name: 'B', price: 460, qty: 1 },
      ],
    });
    expect(lineTotals.items).toEqual([
      { name: 'A', price: 200, quantity: 2 },
      { name: 'B', price: 460, quantity: 1 },
    ]);

    const unitPrices = normalizeReading({
      total: 860,
      items: [
        { name: 'A', price: 400, qty: 2 },
        { name: 'B', price: 60, qty: 1 },
      ],
    });
    expect(unitPrices.items.reduce((sum, item) => sum + item.price * item.quantity, 0)).toBe(860);
  });

  it('normalizes receipt adjustments from the reader response', () => {
    const r = normalizeReading({ total: 860, tax: 100, discount: 20, cash_paid: 1000, change: 140, items: [] });
    expect(r.tax).toBe(100);
    expect(r.discount).toBe(20);
    expect(r.cashPaid).toBe(1000);
    expect(r.change).toBe(140);
  });

  it('an unreadable photo is passed on as unreadable', () => {
    expect(normalizeReading({ total: null, items: [], readable: false, needs_review: true }).readable).toBe(false);
  });

  it('the manual reader returns an empty receipt flagged for review', async () => {
    const r = await manualReader.read(Buffer.alloc(0));
    expect(r.items).toEqual([]);
    expect(r.readerNeedsReview).toBe(true);
  });

  it('the http reader posts the JPEG with the token and cleans the answer', async () => {
    let seen: { url: string; init: RequestInit } | undefined;
    const reader = createHttpReader({
      url: 'http://reader:8000/',
      token: 'secret',
      timeoutMs: 1000,
      fetchImpl: (async (url: string, init: RequestInit) => {
        seen = { url, init };
        return new Response(JSON.stringify({ total: 10, items: [{ name: 'Tea', price: 10, category: 'Groceries' }], confidence: 0.9 }), { status: 200 });
      }) as unknown as typeof fetch,
    });
    const out = await reader.read(Buffer.from([0xff, 0xd8, 0xff, 0x00]));
    expect(seen!.url).toBe('http://reader:8000/read');
    expect((seen!.init.headers as Record<string, string>).Authorization).toBe('Bearer secret');
    expect(out.items[0].name).toBe('Tea');
  });

  it('the http reader throws when the reader service errors (receipt becomes failed)', async () => {
    const reader = createHttpReader({
      url: 'http://reader:8000',
      timeoutMs: 1000,
      fetchImpl: (async () => new Response('no', { status: 503 })) as unknown as typeof fetch,
    });
    await expect(reader.read(Buffer.from([1, 2, 3]))).rejects.toThrow('503');
  });
});

describe('category mapping', () => {
  it('maps the reader\'s eight labels to Kharcha categories', () => {
    expect(categoryNameFor('Dining', 'Momo')).toBe('Food & Dining');
    expect(categoryNameFor('Health', 'Tablet')).toBe('Healthcare');
    expect(categoryNameFor('Bills', 'Data pack')).toBe('Utilities');
  });
  it('uses keyword rules when the reader says Other or nothing', () => {
    expect(categoryNameFor(null, 'Petrol')).toBe('Transport');
  });
  it('keeps reader-supported categories when keyword rules do not match', () => {
    expect(categoryNameFor('Health', 'Shampoo')).toBe('Healthcare');
    expect(categoryNameFor('Health', 'Paracetamol')).toBe('Healthcare');
  });
  it('leaves it open when nothing matches', () => {
    expect(categoryNameFor(null, 'zzzz')).toBeNull();
    expect(categoryNameFor('Other', 'zzzz')).toBe('Other');
  });
  it('correction keys ignore sizes and punctuation', () => {
    expect(correctionKey('TEA 250g')).toBe('tea');
    expect(correctionKey('Tea, 500 ml!')).toBe('tea');
  });
});
