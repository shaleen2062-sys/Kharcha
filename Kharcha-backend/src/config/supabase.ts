import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from './env';
import { ApiError } from '../utils/ApiError';

let client: SupabaseClient | null = null;

/** Server-side Supabase client (service role). Only used when STORAGE_MODE=supabase. */
export function getSupabase(): SupabaseClient {
  if (client) return client;
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    throw ApiError.internal('Supabase is not configured (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY)');
  }
  client = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return client;
}
