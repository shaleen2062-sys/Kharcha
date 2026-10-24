import { Types } from 'mongoose';
import { Receipt } from '../receipts/receipt.model';
import { categoryIndex } from '../categories/categoryLookup';
import { monthSummary, monthlyTotals, StatReceipt } from './stats';
import { dateInTz, monthOf } from '../utils/dates';
import { env } from '../config/env';
import { User } from '../users/user.model';

async function statReceipts(userId: Types.ObjectId): Promise<StatReceipt[]> {
  const rows = await Receipt.find({ userId, status: 'confirmed', deletedAt: null }).lean();
  return rows.map((r) => ({
    status: r.status,
    total: r.total,
    date: r.date,
    createdAt: r.createdAt,
    items: r.items.map((i) => ({ price: i.price, quantity: i.quantity, categoryId: i.categoryId ? String(i.categoryId) : null })),
  }));
}

const thisMonth = (): string => monthOf(dateInTz(env.APP_TZ));

export async function summary(userId: Types.ObjectId, month: string = thisMonth()) {
  const [receipts, cats, user] = await Promise.all([statReceipts(userId), categoryIndex(userId), User.findById(userId).lean()]);
  return monthSummary(receipts, month, env.APP_TZ, cats, user?.currency ?? 'NPR');
}

export async function trend(userId: Types.ObjectId, months = 6, endMonth: string = thisMonth()) {
  const [receipts, user] = await Promise.all([statReceipts(userId), User.findById(userId).lean()]);
  return monthlyTotals(receipts, endMonth, months, env.APP_TZ, user?.currency ?? 'NPR');
}
