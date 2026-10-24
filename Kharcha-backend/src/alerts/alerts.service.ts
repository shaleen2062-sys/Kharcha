import { Types } from 'mongoose';
import { Alert, AlertType } from './alert.model';
import { Budget } from '../budgets/budget.model';
import { limitsInMonth } from '../budgets/budgetLimits';
import { Receipt } from '../receipts/receipt.model';
import { User } from '../users/user.model';
import { categoryIndex } from '../categories/categoryLookup';
import { spentByCategoryId, StatReceipt } from '../dashboard/stats';
import { dateInTz, monthOf } from '../utils/dates';
import { env } from '../config/env';
import { ApiError } from '../utils/ApiError';
import { logger } from '../utils/logger';

const fmt = (n: number): string => Math.round(n).toLocaleString('en-US');

/** Creates an alert once per (user, type, subject); a repeat is silently ignored. Returns true when new. */
export async function raise(
  userId: Types.ObjectId,
  type: AlertType,
  subject: string,
  fields: { message: string; categoryId?: Types.ObjectId | null; receiptId?: Types.ObjectId | null; month?: string | null; percent?: number | null },
): Promise<boolean> {
  try {
    await Alert.create({ userId, type, subject, ...fields });
    return true;
  } catch (err) {
    if ((err as { code?: number }).code === 11000) return false;
    throw err;
  }
}

/**
 * Warns while the month is still running: when a category reaches the user's alert level (default 80%)
 * of its limit, and again when it passes 100%. Only the CURRENT month is checked; each alert fires once.
 */
export async function evaluateBudgetAlerts(userId: Types.ObjectId, month?: string): Promise<number> {
  const current = monthOf(dateInTz(env.APP_TZ));
  const target = month ?? current;
  if (target !== current) return 0;

  const user = await User.findById(userId).lean();
  if (!user || user.notificationsEnabled === false) return 0;
  const alertPercent = user.alertPercent ?? 80;

  const [history, receipts, cats] = await Promise.all([
    Budget.find({ userId }).lean(),
    Receipt.find({ userId, status: 'confirmed', deletedAt: null }).lean(),
    categoryIndex(userId),
  ]);

  const limits = limitsInMonth(
    history.map((h) => ({ categoryId: String(h.categoryId), effectiveFrom: h.effectiveFrom, limit: h.limit ?? null })),
    target,
  );
  if (limits.size === 0) return 0;

  const stat: StatReceipt[] = receipts.map((r) => ({
    status: r.status,
    total: r.total,
    date: r.date,
    createdAt: r.createdAt,
    items: r.items.map((i) => ({ price: i.price, quantity: i.quantity, categoryId: i.categoryId ? String(i.categoryId) : null })),
  }));
  const spent = spentByCategoryId(stat, target, env.APP_TZ, cats);

  let created = 0;
  for (const [categoryId, limit] of limits) {
    if (limit <= 0) continue;
    const amount = spent.get(categoryId) ?? 0;
    const percent = Math.round((amount / limit) * 100);
    const name = cats.names.get(categoryId) ?? 'a category';
    const base = { categoryId: new Types.ObjectId(categoryId), month: target, percent };
    if (percent >= 100) {
      const made = await raise(userId, 'budget_exceeded', `${categoryId}:${target}`, {
        ...base,
        message: `${name} is over budget: ${fmt(amount)} spent of ${fmt(limit)}.`,
      });
      if (made) created++;
    }
    if (percent >= alertPercent) {
      const made = await raise(userId, 'budget_warning', `${categoryId}:${target}`, {
        ...base,
        message: `${name} has reached ${percent}% of its budget (${fmt(amount)} of ${fmt(limit)}).`,
      });
      if (made) created++;
    }
  }
  if (created > 0) logger.info({ userId, created }, 'Budget alerts raised');
  return created;
}

export async function listAlerts(userId: Types.ObjectId, unreadOnly: boolean, limit = 100) {
  const filter = { userId, ...(unreadOnly ? { readAt: null } : {}) };
  const [alerts, unreadCount] = await Promise.all([
    Alert.find(filter).sort({ createdAt: -1 }).limit(limit),
    Alert.countDocuments({ userId, readAt: null }),
  ]);
  return { alerts, unreadCount };
}

export async function markRead(userId: Types.ObjectId, id: string) {
  if (!Types.ObjectId.isValid(id)) throw ApiError.notFound('Alert');
  const alert = await Alert.findOneAndUpdate({ _id: id, userId }, { $set: { readAt: new Date() } }, { new: true });
  if (!alert) throw ApiError.notFound('Alert');
  return alert;
}

export async function markAllRead(userId: Types.ObjectId): Promise<void> {
  await Alert.updateMany({ userId, readAt: null }, { $set: { readAt: new Date() } });
}
