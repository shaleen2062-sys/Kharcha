import request from 'supertest';
import { UrlSigner, MemoryStorage, setStorage, signer } from '../../src/storage/storage';
import { createApp } from '../../src/app';

describe('signed links', () => {
  it('verify only before they expire and only for the right name', () => {
    let now = new Date('2026-10-23T10:00:00Z');
    const s = new UrlSigner('k', 'http://x', 60, () => now);
    const url = new URL(s.sign('a.jpg'));
    const exp = url.searchParams.get('exp'), sig = url.searchParams.get('sig');
    expect(s.verify('a.jpg', exp, sig)).toBe(true);
    expect(s.verify('b.jpg', exp, sig)).toBe(false);
    expect(s.verify('a.jpg', exp, 'f'.repeat(64))).toBe(false);
    now = new Date('2026-10-23T10:02:00Z');
    expect(s.verify('a.jpg', exp, sig)).toBe(false);
  });
});

describe('HTTP smoke tests (no database needed)', () => {
  const app = createApp();

  it('health is public', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
  });

  it.each(['/api/receipts', '/api/budgets', '/api/alerts', '/api/dashboard/summary', '/api/categories', '/api/users/me'])(
    '%s needs a login',
    async (path) => {
      const res = await request(app).get(path);
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    },
  );

  it('serves a photo only to a valid signed link', async () => {
    const storage = new MemoryStorage(signer);
    setStorage(storage);
    const name = await storage.save(Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]));
    const link = new URL(await storage.signedUrl(name));
    const ok = await request(app).get(`${link.pathname}${link.search}`);
    expect(ok.status).toBe(200);
    expect(ok.headers['content-type']).toContain('image/jpeg');
    const bad = await request(app).get(`${link.pathname}?exp=${link.searchParams.get('exp')}&sig=wrong`);
    expect(bad.status).toBe(403);
    setStorage(null);
  });

  it('unknown routes are a clean 404', async () => {
    const res = await request(app).get('/api/nope');
    expect(res.status).toBe(404);
  });
});
