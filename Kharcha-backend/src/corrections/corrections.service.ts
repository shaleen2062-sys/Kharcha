import { Types } from 'mongoose';
import { Correction } from './correction.model';

/** Same name written in different ways ("TEA 250g", "tea") maps to the same key. */
export function correctionKey(name: string): string {
  return name
    .toLowerCase()
    .replace(/[0-9]+(\.[0-9]+)?\s*(g|gm|kg|ml|l|ltr|pcs|pc|pk)\b/g, ' ')
    .replace(/[^\p{L}\p{M}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Remembers the user's category for each item they changed. */
export async function learn(
  userId: Types.ObjectId,
  changes: Array<{ name: string; categoryId: Types.ObjectId }>,
): Promise<void> {
  for (const c of changes) {
    const key = correctionKey(c.name);
    if (!key) continue;
    await Correction.findOneAndUpdate(
      { userId, key },
      { $set: { categoryId: c.categoryId }, $inc: { count: 1 } },
      { upsert: true },
    );
  }
}

/** key -> categoryId for the given item names (only those the user has corrected before). */
export async function lookup(userId: Types.ObjectId, names: string[]): Promise<Map<string, Types.ObjectId>> {
  const keys = [...new Set(names.map(correctionKey).filter(Boolean))];
  if (keys.length === 0) return new Map();
  const rows = await Correction.find({ userId, key: { $in: keys } }).lean();
  return new Map(rows.map((r) => [r.key, r.categoryId as Types.ObjectId]));
}
