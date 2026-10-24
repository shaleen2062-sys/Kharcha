import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(4000),
  PUBLIC_BASE_URL: z.string().default('http://localhost:4000'),
  CORS_ORIGINS: z.string().default(''),

  AUTH_MODE: z.enum(['firebase', 'dev']).default('dev'),
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),

  MONGODB_URI: z.string().default('mongodb://127.0.0.1:27017/kharcha'),

  // What "this month" means for dashboards and budgets
  APP_TZ: z.string().default('Asia/Kathmandu'),

  // Receipt photo storage: local disk (dev) or Supabase Storage (production)
  STORAGE_MODE: z.enum(['local', 'supabase', 'memory']).default('local'),
  UPLOAD_DIR: z.string().default('./uploads'),
  MAX_UPLOAD_MB: z.coerce.number().positive().default(10),
  URL_SIGNING_SECRET: z.string().default('dev-only-change-me'),
  IMAGE_URL_TTL_SECONDS: z.coerce.number().int().positive().default(3600),
  SUPABASE_URL: z.string().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SUPABASE_BUCKET: z.string().default('receipts'),

  // The AI reader (see ../reader). manual = user types the receipt in.
  READER: z.enum(['manual', 'http']).default('manual'),
  READER_URL: z.string().optional(),
  READER_TOKEN: z.string().optional(),
  READER_TIMEOUT_MS: z.coerce.number().int().positive().default(120000),
  READER_MIN_CONFIDENCE: z.coerce.number().min(0).max(1).default(0.7),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment variables:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

if (parsed.data.NODE_ENV === 'production' && parsed.data.URL_SIGNING_SECRET === 'dev-only-change-me') {
  console.error('URL_SIGNING_SECRET must be set in production.');
  process.exit(1);
}
if (parsed.data.NODE_ENV === 'production') {
  if (parsed.data.AUTH_MODE !== 'firebase') {
    console.error('AUTH_MODE=firebase is required in production.');
    process.exit(1);
  }
  if (!parsed.data.FIREBASE_PROJECT_ID || !parsed.data.FIREBASE_CLIENT_EMAIL || !parsed.data.FIREBASE_PRIVATE_KEY) {
    console.error('Production Firebase Admin credentials are required.');
    process.exit(1);
  }
  if (parsed.data.MONGODB_URI.startsWith('mongodb://127.0.0.1') || parsed.data.MONGODB_URI.startsWith('mongodb://localhost')) {
    console.error('Production MONGODB_URI must point to a reachable database.');
    process.exit(1);
  }
  if (parsed.data.STORAGE_MODE !== 'supabase') {
    console.error('STORAGE_MODE=supabase is required in production.');
    process.exit(1);
  }
}
if (parsed.data.READER === 'http' && !parsed.data.READER_URL) {
  console.error('READER=http needs READER_URL.');
  process.exit(1);
}
if (parsed.data.STORAGE_MODE === 'supabase' && (!parsed.data.SUPABASE_URL || !parsed.data.SUPABASE_SERVICE_ROLE_KEY)) {
  console.error('STORAGE_MODE=supabase needs SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
  process.exit(1);
}

export const env = {
  ...parsed.data,
  FIREBASE_PRIVATE_KEY: parsed.data.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  CORS_ORIGINS: parsed.data.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean),
};

export type Env = typeof env;