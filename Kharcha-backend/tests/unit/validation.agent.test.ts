import { validateReading, Reading } from '../../src/agents/validation.agent';

const good = (over: Partial<Reading> = {}): Reading => ({
  merchant: 'Bhat-Bhateni',
  total: 1000,
  date: '2026-10-03',
  currency: 'NPR',
  confidence: 0.9,
  items: [
    { name: 'Rice', price: 600, quantity: 1 },
    { name: 'Oil', price: 200, quantity: 2 },
  ],
  ...over,
});
const run = (reading: Reading, recent: Parameters<typeof validateReading>[0]['recent'] = []) =>
  validateReading({ reading, minConfidence: 0.7, today: '2026-10-23', recent });

describe('validation agent', () => {
  it('confirms a clean receipt on its own', () => {
    expect(run(good())).toEqual({ status: 'confirmed', reasons: [] });
  });

  it('does not create a review from low confidence alone', () => {
    expect(run(good({ confidence: 0.4 }))).toEqual({ status: 'confirmed', reasons: [] });
  });

  it('respects the reader\'s own review flag', () => {
    const v = run(good({ readerNeedsReview: true }));
    expect(v.status).toBe('needs_review');
    expect(v.reasons).toContain('reader_flagged');
  });

  it('uses the reader flag even when the reading is otherwise empty', () => {
    const v = run({ merchant: null, total: null, date: null, currency: 'NPR', items: [], readerNeedsReview: true });
    expect(v.status).toBe('needs_review');
    expect(v.reasons).toEqual(['reader_flagged']);
  });

  it('does not create a review from a total mismatch alone', () => {
    expect(run(good({ confidence: undefined, total: 5000 }))).toEqual({ status: 'confirmed', reasons: [] });
  });

  it('does not create a review from a total gap', () => {
    expect(run(good({ total: 1130 })).status).toBe('confirmed');
  });

  it('does not create a review from a date alone', () => {
    expect(run(good({ date: '2015-01-01' })).status).toBe('confirmed');
  });

  it('a missing date does not create a review', () => {
    expect(run(good({ date: null })).status).toBe('confirmed');
  });

  it('does not create a review from a possible duplicate', () => {
    expect(run(good(), [{ id: 'abc', merchant: 'BHAT BHATENI', total: 1000, date: '2026-10-03' }])).toEqual({
      status: 'confirmed',
      reasons: [],
    });
  });

  it('does not call a different day a duplicate', () => {
    expect(run(good(), [{ merchant: 'Bhat-Bhateni', total: 1000, date: '2026-10-02' }]).status).toBe('confirmed');
  });

  it('uses only the reader flag for unreadable photos', () => {
    expect(run(good({ readable: false })).status).toBe('confirmed');
  });
});
