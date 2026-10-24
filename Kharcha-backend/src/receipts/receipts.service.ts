import { Types } from 'mongoose';
import { Receipt, ReceiptDoc } from './receipt.model';
import { UpdateReceiptBody, idempotencyKey } from './receipts.schemas';
import { getStorage } from '../storage/storage';
import { categoryIndex, CategoryIndex } from '../categories/categoryLookup';
import { learn, correctionKey } from '../corrections/corrections.service';
import { processReceipt } from '../agents/processReceipt';
import { evaluateBudgetAlerts } from '../alerts/alerts.service';
import { queue } from '../jobs/queue';
import { ApiError } from '../utils/ApiError';
import { effectiveDate, monthOf } from '../utils/dates';
import { env } from '../config/env';

const isJpeg = (b: Buffer): boolean => b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff;

/** Receipt as the API sends it: no internals, a fresh signed image link, category names resolved. */
export async function toApi(r: ReceiptDoc, cats: CategoryIndex) {
  const name = (id: unknown): string | null => (id ? cats.names.get(String(id)) ?? null : null);
  return {
    id: String(r._id),
    status: r.status,
    merchant: r.merchant ?? null,
    total: r.total ?? null,
    tax: r.tax ?? null,
    discount: r.discount ?? null,
    cashPaid: r.cashPaid ?? null,
    change: r.change ?? null,
    currency: r.currency || 'NPR',
    date: r.date ?? null,
    imageUrl: r.imagePath ? await getStorage().signedUrl(r.imagePath) : null,
    confidence: r.confidence ?? null,
    confidenceReason: r.confidenceReason ?? null,
    reviewReasons: r.reviewReasons ?? [],
    createdAt: r.createdAt,
    items: r.items.map((i) => ({
      name: i.name,
      price: i.price,
      quantity: i.quantity || 1,
      categoryId: i.categoryId ? String(i.categoryId) : null,
      category: name(i.categoryId),
    })),
  };
}

export async function presentOne(userId: Types.ObjectId, r: ReceiptDoc) {
  return toApi(r, await categoryIndex(userId));
}

export async function presentMany(userId: Types.ObjectId, rs: ReceiptDoc[]) {
  const cats = await categoryIndex(userId);
  return Promise.all(rs.map((r) => toApi(r, cats)));
}

/** Saves the photo and starts reading it. The same Idempotency-Key from the same user returns the first receipt again. */
export async function createFromUpload(
  userId: Types.ObjectId,
  input: { buffer: Buffer; idempotencyKey?: string },
): Promise<{ receipt: ReceiptDoc; created: boolean }> {
  const key = input.idempotencyKey;
  if (key != null) {
    const ok = idempotencyKey.safeParse(key);
    if (!ok.success) throw new ApiError(422, ok.error.issues[0].message, 'VALIDATION_ERROR');
    const existing = await Receipt.findOne({ userId, idempotencyKey: key });
    if (existing) return { receipt: existing, created: false };
  }
  if (!isJpeg(input.buffer)) throw new ApiError(422, 'That file is not a photo we can read.', 'INVALID_IMAGE');

  const storage = getStorage();
  const imagePath = await storage.save(input.buffer);
  let receipt: ReceiptDoc;
  try {
    receipt = await Receipt.create({ userId, status: 'processing', imagePath, idempotencyKey: key });
  } catch (err) {
    await storage.remove(imagePath).catch(() => undefined);
    // Two uploads with the same key at the same moment: keep the first.
    if ((err as { code?: number }).code === 11000 && key) {
      const first = await Receipt.findOne({ userId, idempotencyKey: key });
      if (first) return { receipt: first, created: false };
    }
    throw err;
  }
  queue.enqueue('process-receipt', () => processReceipt(receipt._id));
  return { receipt, created: true };
}

export async function listReceipts(
  userId: Types.ObjectId,
  q: { status?: string; month?: string; limit: number },
): Promise<ReceiptDoc[]> {
  const filter: Record<string, unknown> = { userId, deletedAt: null };
  if (q.status) filter.status = q.status;
  if (q.month) filter.date = { $regex: `^${q.month}` };
  return Receipt.find(filter).sort({ createdAt: -1 }).limit(q.limit);
}

export async function getReceipt(userId: Types.ObjectId, id: string): Promise<ReceiptDoc> {
  if (!Types.ObjectId.isValid(id)) throw ApiError.notFound('Receipt');
  const r = await Receipt.findOne({ _id: id, userId, deletedAt: null });
  if (!r) throw ApiError.notFound('Receipt');
  return r;
}

/** The user's corrections: saves the receipt as confirmed, and remembers every category they changed. */
export async function confirmReceipt(userId: Types.ObjectId, id: string, body: UpdateReceiptBody): Promise<ReceiptDoc> {
  const r = await getReceipt(userId, id);
  if (r.status === 'processing') throw ApiError.conflict('This receipt is still being read. Try again in a moment.');

  const cats = await categoryIndex(userId);
  const previous = new Map(r.items.map((i) => [correctionKey(i.name), i]));
  const changes: Array<{ name: string; categoryId: Types.ObjectId }> = [];

  const items = body.items.map((raw, n) => {
    let categoryId: Types.ObjectId | null = null;
    if (raw.categoryId) {
      if (!cats.names.has(raw.categoryId)) throw new ApiError(422, `Item ${n + 1} has an unknown category.`, 'VALIDATION_ERROR');
      categoryId = new Types.ObjectId(raw.categoryId);
    } else if (raw.category) {
      const found = cats.idByName.get(raw.category.toLowerCase());
      if (!found) throw new ApiError(422, `Item ${n + 1} has an unknown category.`, 'VALIDATION_ERROR');
      categoryId = new Types.ObjectId(found);
    }
    const before = previous.get(correctionKey(raw.name));
    if (categoryId && before && String(before.categoryId ?? '') !== String(categoryId)) {
      changes.push({ name: raw.name, categoryId });
    }
    return { name: raw.name, price: raw.price, quantity: raw.quantity ?? 1, categoryId, aiCategoryId: before?.aiCategoryId ?? null };
  });

  if (body.merchant !== undefined) r.merchant = body.merchant || null;
  if (body.total !== undefined) r.total = body.total;
  if (body.currency) r.currency = body.currency;
  if (body.date !== undefined) r.date = body.date;
  r.items.splice(0, r.items.length, ...items);
  r.status = 'confirmed';
  r.reviewReasons = [];
  await r.save();

  if (changes.length > 0) await learn(userId, changes);
  await evaluateBudgetAlerts(userId, monthOf(effectiveDate(r, env.APP_TZ)));
  return r;
}

export async function deleteReceipt(userId: Types.ObjectId, id: string): Promise<void> {
  const r = await getReceipt(userId, id);
  r.deletedAt = new Date();
  await r.save();
  if (r.imagePath) await getStorage().remove(r.imagePath).catch(() => undefined);
}
