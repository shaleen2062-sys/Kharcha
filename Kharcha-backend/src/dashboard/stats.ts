import { daysInMonth, effectiveDate, monthOf, prevMonth } from '../utils/dates';
import { itemsSum, round2 } from '../utils/money';

/** Plain shapes so the maths can be tested without a database. */
export interface StatItem {
  price: number;
  quantity?: number | null;
  categoryId?: string | null;
}
export interface StatReceipt {
  status: string;
  total?: number | null;
  date?: string | null;
  createdAt?: Date;
  items: StatItem[];
}
export interface CategoryNames {
  /** id -> display name */
  names: Map<string, string>;
  /** where items without a category are counted */
  fallbackId: string;
}

export interface CategoryAmount {
  categoryId: string;
  category: string;
  amount: number;
}

/** What the receipt cost: the printed total, or the items added up if there is none. */
export const receiptTotal = (r: StatReceipt): number =>
  typeof r.total === 'number' ? r.total : itemsSum(r.items);

/** Only confirmed receipts count, and only those dated in `month`. */
export function inMonth(receipts: StatReceipt[], month: string, tz: string): StatReceipt[] {
  return receipts.filter((r) => r.status === 'confirmed' && monthOf(effectiveDate(r, tz)) === month);
}

/** categoryId -> amount spent in `month`, from line items. */
export function spentByCategoryId(
  receipts: StatReceipt[],
  month: string,
  tz: string,
  cats: CategoryNames,
): Map<string, number> {
  const out = new Map<string, number>();
  for (const r of inMonth(receipts, month, tz)) {
    for (const i of r.items) {
      const id = i.categoryId && cats.names.has(i.categoryId) ? i.categoryId : cats.fallbackId;
      out.set(id, (out.get(id) ?? 0) + i.price * (i.quantity || 1));
    }
  }
  for (const [k, v] of out) out.set(k, round2(v));
  return out;
}

const toRows = (m: Map<string, number>, cats: CategoryNames): CategoryAmount[] =>
  [...m.entries()]
    .map(([categoryId, amount]) => ({ categoryId, category: cats.names.get(categoryId) ?? 'Uncategorized', amount }))
    .sort((a, b) => b.amount - a.amount);

export function monthSummary(
  receipts: StatReceipt[],
  month: string,
  tz: string,
  cats: CategoryNames,
  currency = 'NPR',
) {
  const rows = inMonth(receipts, month, tz);
  const daily = Array.from({ length: daysInMonth(month) }, (_, i) => ({ day: i + 1, amount: 0 }));
  let total = 0;
  for (const r of rows) {
    const t = receiptTotal(r);
    total += t;
    const day = Number(effectiveDate(r, tz).slice(8, 10));
    daily[day - 1].amount += t;
  }
  const prev = prevMonth(month);
  const prevTotal = inMonth(receipts, prev, tz).reduce((s, r) => s + receiptTotal(r), 0);
  return {
    month,
    currency,
    total: round2(total),
    previousTotal: round2(prevTotal),
    receiptCount: rows.length,
    byCategory: toRows(spentByCategoryId(receipts, month, tz, cats), cats),
    previousByCategory: toRows(spentByCategoryId(receipts, prev, tz, cats), cats),
    daily: daily.map((d) => ({ day: d.day, amount: round2(d.amount) })),
  };
}

/** Totals of the `count` months ending at `endMonth`, oldest first, zeros included. */
export function monthlyTotals(receipts: StatReceipt[], endMonth: string, count: number, tz: string, currency = 'NPR') {
  const months = [endMonth];
  while (months.length < count) months.unshift(prevMonth(months[0]));
  return {
    currency,
    months: months.map((month) => ({
      month,
      total: round2(inMonth(receipts, month, tz).reduce((s, r) => s + receiptTotal(r), 0)),
    })),
  };
}
