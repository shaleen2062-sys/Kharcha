import { Types } from 'mongoose';
import { Budget } from './budget.model';
import { limitsInMonth } from './budgetLimits';
import { Receipt } from '../receipts/receipt.model';
import { categoryIndex } from '../categories/categoryLookup';
import { getCategoryById } from '../categories/categories.service';
import { spentByCategoryId, StatReceipt } from '../dashboard/stats';
import { evaluateBudgetAlerts } from '../alerts/alerts.service';
import { dateInTz, monthOf } from '../utils/dates';
import { round2 } from '../utils/money';
import { env } from '../config/env';

const thisMonth = (): string => monthOf(dateInTz(env.APP_TZ));

export interface BudgetView {
  categoryId: string;
  category: string;
  limit: number;
  spent: number;
  currency: string;
}

/** The budgets in force in `month` (default: this month), with what was spent in that month. */
export async function listBudgets(userId: Types.ObjectId, month: string = thisMonth()): Promise<BudgetView[]> {
  const [history, receipts, cats] = await Promise.all([
    Budget.find({ userId }).lean(),
    Receipt.find({ userId, status: 'confirmed', deletedAt: null }).lean(),
    categoryIndex(userId),
  ]);
  const limits = limitsInMonth(
    history.map((h) => ({ categoryId: String(h.categoryId), effectiveFrom: h.effectiveFrom, limit: h.limit ?? null })),
    month,
  );
  const stat: StatReceipt[] = receipts.map((r) => ({
    status: r.status,
    total: r.total,
    date: r.date,
    createdAt: r.createdAt,
    items: r.items.map((i) => ({ price: i.price, quantity: i.quantity, categoryId: i.categoryId ? String(i.categoryId) : null })),
  }));
  const spent = spentByCategoryId(stat, month, env.APP_TZ, cats);
  return [...limits.entries()]
    .filter(([id]) => cats.names.has(id))
    .map(([categoryId, limit]) => ({
      categoryId,
      category: cats.names.get(categoryId)!,
      limit,
      spent: round2(spent.get(categoryId) ?? 0),
      currency: 'NPR',
    }))
    .sort((a, b) => a.category.localeCompare(b.category));
}

/** Sets the limit from `effectiveFrom` on. Earlier months keep their old limit. */
export async function setBudget(
  userId: Types.ObjectId,
  categoryId: string,
  limit: number,
  effectiveFrom: string = thisMonth(),
): Promise<BudgetView> {
  const cat = await getCategoryById(userId, categoryId);
  await Budget.findOneAndUpdate(
    { userId, categoryId: cat._id, effectiveFrom },
    { $set: { limit } },
    { upsert: true, new: true },
  );
  await evaluateBudgetAlerts(userId, effectiveFrom);
  const view = (await listBudgets(userId, effectiveFrom)).find((b) => b.categoryId === String(cat._id));
  return view!;
}

/** "No budget from this month on". Earlier months are untouched. */
export async function removeBudget(
  userId: Types.ObjectId,
  categoryId: string,
  effectiveFrom: string = thisMonth(),
): Promise<void> {
  const cat = await getCategoryById(userId, categoryId);
  await Budget.findOneAndUpdate({ userId, categoryId: cat._id, effectiveFrom }, { $set: { limit: null } }, { upsert: true });
}
