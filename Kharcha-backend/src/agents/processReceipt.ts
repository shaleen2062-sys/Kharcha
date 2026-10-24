import { Types } from 'mongoose';
import { Receipt } from '../receipts/receipt.model';
import { AgentRun } from './agentRun.model';
import { validateReading, Reading } from './validation.agent';
import { getReader, RawItem } from '../receipts/reader.client';
import { getStorage } from '../storage/storage';
import { categoryIndex } from '../categories/categoryLookup';
import { categoryNameFor } from '../categories/readerCategories';
import { lookup as lookupCorrections, correctionKey } from '../corrections/corrections.service';
import { evaluateBudgetAlerts, raise } from '../alerts/alerts.service';
import { dateInTz, monthOf, effectiveDate } from '../utils/dates';
import { queue } from '../jobs/queue';
import { env } from '../config/env';
import { logger } from '../utils/logger';

async function record(
  userId: Types.ObjectId,
  receiptId: Types.ObjectId,
  agent: 'reader' | 'validation' | 'alerts',
  startedAt: number,
  ok: boolean,
  summary: Record<string, unknown>,
  error?: string,
): Promise<void> {
  try {
    await AgentRun.create({ userId, receiptId, agent, ok, durationMs: Date.now() - startedAt, summary, error: error ?? null });
  } catch (err) {
    logger.warn({ err }, 'Could not record agent run');
  }
}

/**
 * Background pipeline for one uploaded photo:
 *   read the photo (reader)  ->  put each item in the user's category (user corrections first, then the
 *   reader's label)  ->  validate  ->  save as confirmed or needs_review  ->  raise alerts.
 * Never throws: a failure marks the receipt "failed" so the user can type it in.
 */
export async function processReceipt(receiptId: string | Types.ObjectId): Promise<void> {
  const receipt = await Receipt.findOne({ _id: receiptId, status: 'processing', deletedAt: null });
  if (!receipt || !receipt.imagePath) return;
  const userId = receipt.userId;
  const reader = getReader();

  // 1. read
  let raw: RawItem;
  const t0 = Date.now();
  try {
    raw = await reader.read(await getStorage().read(receipt.imagePath));
    await record(userId, receipt._id, 'reader', t0, true, {
      reader: reader.name,
      confidence: raw.confidence ?? null,
      confidenceReason: raw.confidenceReason ?? null,
      items: raw.items.length,
      readerNeedsReview: raw.readerNeedsReview ?? false,
      reconciliation: raw.reconciliation ?? null,
    });
  } catch (err) {
    logger.error({ err, receiptId: String(receipt._id) }, 'Reading receipt failed');
    await record(userId, receipt._id, 'reader', t0, false, { reader: reader.name }, String((err as Error)?.message ?? err));
    receipt.status = 'failed';
    receipt.reviewReasons = ['unreadable'];
    await receipt.save();
    return;
  }

  // 2. categories: what this user corrected before wins, then the reader's label, else left for the user
  const cats = await categoryIndex(userId);
  const learned = await lookupCorrections(userId, raw.items.map((i) => i.name));
  const items = raw.items.map((i, idx) => {
    const fromUser = learned.get(correctionKey(i.name));
    let id: Types.ObjectId | null = fromUser ?? null;
    if (!id) {
      const name = categoryNameFor(raw.itemLabels[idx], i.name);
      const found = name ? cats.idByName.get(name.toLowerCase()) : undefined;
      id = found ? new Types.ObjectId(found) : null;
    }
    return { name: i.name, price: i.price, quantity: i.quantity, categoryId: id, aiCategoryId: id };
  });

  // 3. validate
  const t1 = Date.now();
  const today = dateInTz(env.APP_TZ);
  const reading: Reading = raw;
  const verdict = validateReading({
    reading,
    minConfidence: env.READER_MIN_CONFIDENCE,
    today,
    recent: [],
  });
  await record(userId, receipt._id, 'validation', t1, true, { status: verdict.status, reasons: verdict.reasons, duplicateOf: verdict.duplicateOf ?? null });

  // 4. save
  receipt.merchant = raw.merchant;
  receipt.total = raw.total;
  receipt.tax = raw.tax ?? null;
  receipt.discount = raw.discount ?? null;
  receipt.cashPaid = raw.cashPaid ?? null;
  receipt.change = raw.change ?? null;
  receipt.currency = raw.currency || 'NPR';
  receipt.date = raw.date;
  receipt.confidence = raw.confidence ?? null;
  receipt.confidenceReason = raw.confidenceReason ?? null;
  receipt.items.splice(0, receipt.items.length, ...items);
  receipt.status = verdict.status;
  receipt.reviewReasons = verdict.reasons;
  receipt.source = reader.name === 'http' ? 'ai' : 'manual';
  await receipt.save();

  // 5. alerts
  const t2 = Date.now();
  let raised = 0;
  if (verdict.status === 'confirmed') {
    const month = monthOf(effectiveDate(receipt, env.APP_TZ));
    raised = await evaluateBudgetAlerts(userId, month);
  } else if (reader.name === 'http') {
    const made = await raise(userId, 'needs_review', String(receipt._id), {
      receiptId: receipt._id,
      message: `A receipt from ${receipt.merchant ?? 'your latest photo'} was flagged by the reader and needs a quick look before it is saved.`,
    });
    if (made) raised++;
  }
  await record(userId, receipt._id, 'alerts', t2, true, { raised });
}

/** Called at server start: receipts left "processing" by a restart are read again. */
export async function requeueStuck(olderThanMs = 60_000): Promise<number> {
  const stuck = await Receipt.find({ status: 'processing', deletedAt: null, updatedAt: { $lt: new Date(Date.now() - olderThanMs) } })
    .select('_id')
    .lean();
  for (const r of stuck) queue.enqueue('process-receipt', () => processReceipt(r._id));
  return stuck.length;
}
