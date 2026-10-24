// Jest setup: pure-logic tests need nothing here. Tests that touch MongoDB use tests/db.ts.
process.env.NODE_ENV = 'test';
process.env.AUTH_MODE = 'dev';
process.env.STORAGE_MODE = 'memory';
process.env.READER = 'manual';
process.env.URL_SIGNING_SECRET = 'test-secret';
