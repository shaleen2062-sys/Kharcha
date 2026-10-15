import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';

let mongo: MongoMemoryServer;

process.env.NODE_ENV = 'test';
process.env.AUTH_MODE = 'dev';
process.env.PORT = '4001';

beforeAll(async () => {
  mongo = await MongoMemoryServer.create();
  process.env.MONGODB_URI = mongo.getUri();
});

afterAll(async () => {
  await mongoose.disconnect();
  if (mongo) await mongo.stop();
});

afterEach(async () => {
  const collections = await mongoose.connection.db?.collections() ?? [];
  for (const c of collections) {
    await c.deleteMany({});
  }
});