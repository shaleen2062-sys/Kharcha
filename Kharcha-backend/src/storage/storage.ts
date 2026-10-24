import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { env } from '../config/env';
import { getSupabase } from '../config/supabase';

/**
 * Where receipt photos live. Three interchangeable implementations:
 *  - LocalStorage     a folder on the server (development)
 *  - SupabaseStorage  a private Supabase bucket (production)
 *  - MemoryStorage    for tests
 * `signedUrl` returns a link the phone can open without sending any header.
 */
export interface ReceiptStorage {
  save(buffer: Buffer): Promise<string>;
  read(name: string): Promise<Buffer>;
  remove(name: string): Promise<void>;
  signedUrl(name: string): Promise<string>;
}

const NAME_RE = /^[A-Za-z0-9_-]+\.jpg$/;
export const isSafeName = (name: string): boolean => NAME_RE.test(name);
const newName = (): string => `${crypto.randomBytes(16).toString('hex')}.jpg`;

/** Links of the form /files/<name>?exp=<unix>&sig=<hmac>: no login header needed, but they expire. */
export class UrlSigner {
  constructor(
    private readonly secret: string,
    private readonly baseUrl: string,
    private readonly ttlSeconds: number,
    private readonly clock: () => Date = () => new Date(),
  ) {}

  private sig(name: string, exp: number): string {
    return crypto.createHmac('sha256', this.secret).update(`${name}:${exp}`).digest('hex');
  }

  sign(name: string): string {
    const exp = Math.floor(this.clock().getTime() / 1000) + this.ttlSeconds;
    return `${this.baseUrl.replace(/\/$/, '')}/files/${name}?exp=${exp}&sig=${this.sig(name, exp)}`;
  }

  verify(name: string, exp: unknown, sig: unknown): boolean {
    const e = Number(exp);
    if (!Number.isInteger(e) || typeof sig !== 'string') return false;
    if (e < Math.floor(this.clock().getTime() / 1000)) return false;
    const expected = Buffer.from(this.sig(name, e));
    const given = Buffer.from(sig);
    return expected.length === given.length && crypto.timingSafeEqual(expected, given);
  }
}

export class LocalStorage implements ReceiptStorage {
  private readonly dir: string;
  constructor(dir: string, private readonly signer: UrlSigner) {
    this.dir = path.resolve(dir);
  }
  private file(name: string): string {
    if (!isSafeName(name)) throw new Error('Bad file name');
    return path.join(this.dir, name);
  }
  async save(buffer: Buffer): Promise<string> {
    await fs.mkdir(this.dir, { recursive: true });
    const name = newName();
    await fs.writeFile(this.file(name), buffer);
    return name;
  }
  read(name: string): Promise<Buffer> {
    return fs.readFile(this.file(name));
  }
  async remove(name: string): Promise<void> {
    await fs.rm(this.file(name), { force: true });
  }
  async signedUrl(name: string): Promise<string> {
    return this.signer.sign(name);
  }
}

export class MemoryStorage implements ReceiptStorage {
  readonly files = new Map<string, Buffer>();
  private n = 0;
  constructor(private readonly signer: UrlSigner) {}
  async save(buffer: Buffer): Promise<string> {
    const name = `mem${++this.n}.jpg`;
    this.files.set(name, Buffer.from(buffer));
    return name;
  }
  async read(name: string): Promise<Buffer> {
    const f = this.files.get(name);
    if (!f) throw new Error('Not found');
    return f;
  }
  async remove(name: string): Promise<void> {
    this.files.delete(name);
  }
  async signedUrl(name: string): Promise<string> {
    return this.signer.sign(name);
  }
}

export class SupabaseStorage implements ReceiptStorage {
  constructor(private readonly bucket: string, private readonly ttlSeconds: number) {}
  async save(buffer: Buffer): Promise<string> {
    const name = newName();
    const { error } = await getSupabase().storage.from(this.bucket).upload(name, buffer, {
      contentType: 'image/jpeg',
      upsert: false,
    });
    if (error) throw new Error(`Supabase upload failed: ${error.message}`);
    return name;
  }
  async read(name: string): Promise<Buffer> {
    const { data, error } = await getSupabase().storage.from(this.bucket).download(name);
    if (error || !data) throw new Error(`Supabase download failed: ${error?.message ?? 'no data'}`);
    return Buffer.from(await data.arrayBuffer());
  }
  async remove(name: string): Promise<void> {
    await getSupabase().storage.from(this.bucket).remove([name]);
  }
  async signedUrl(name: string): Promise<string> {
    const { data, error } = await getSupabase().storage.from(this.bucket).createSignedUrl(name, this.ttlSeconds);
    if (error || !data) throw new Error(`Supabase signing failed: ${error?.message ?? 'no data'}`);
    return data.signedUrl;
  }
}

export const signer = new UrlSigner(env.URL_SIGNING_SECRET, env.PUBLIC_BASE_URL, env.IMAGE_URL_TTL_SECONDS);

let storage: ReceiptStorage | null = null;
export function getStorage(): ReceiptStorage {
  if (storage) return storage;
  switch (env.STORAGE_MODE) {
    case 'supabase':
      storage = new SupabaseStorage(env.SUPABASE_BUCKET, env.IMAGE_URL_TTL_SECONDS);
      break;
    case 'memory':
      storage = new MemoryStorage(signer);
      break;
    default:
      storage = new LocalStorage(env.UPLOAD_DIR, signer);
  }
  return storage;
}

/** For tests. */
export function setStorage(s: ReceiptStorage | null): void {
  storage = s;
}
