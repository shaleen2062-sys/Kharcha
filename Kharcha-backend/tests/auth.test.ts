import request from 'supertest';
import { createApp } from '../src/app';

// Auth failures need no database: requireAuth rejects before any query runs.
describe('auth', () => {
  const app = createApp();

  it('rejects a request with no token', async () => {
    const res = await request(app).get('/api/users/me');
    expect(res.status).toBe(401);
  });

  it('rejects a malformed Authorization header', async () => {
    const res = await request(app).get('/api/users/me').set('Authorization', 'Token abc');
    expect(res.status).toBe(401);
  });

  it('in dev mode rejects tokens that are not "dev:<uid>"', async () => {
    const res = await request(app).get('/api/users/me').set('Authorization', 'Bearer something');
    expect(res.status).toBe(401);
  });
});
