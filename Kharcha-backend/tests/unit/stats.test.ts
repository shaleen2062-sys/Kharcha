import { monthSummary, monthlyTotals, spentByCategoryId, StatReceipt, CategoryNames } from '../../src/dashboard/stats';
import { limitsInMonth } from '../../src/budgets/budgetLimits';
import { prevMonth, daysInMonth, isValidDate, isValidMonth, daysBetween } from '../../src/utils/dates';

const cats: CategoryNames = {
  names: new Map([['g', 'Groceries'], ['d', 'Food & Dining'], ['u', 'Uncategorized']]),
  fallbackId: 'u',
};
const r = (date: string, status: string, total: number | null, items: Array<[number, number, string | null]>): StatReceipt => ({
  status,
  date,
  total,
  items: items.map(([price, quantity, categoryId]) => ({ price, quantity, categoryId })),
});

const data: StatReceipt[] = [
  r('2026-10-02', 'confirmed', 1000, [[500, 2, 'g']]),
  r('2026-10-02', 'confirmed', 300, [[300, 1, 'd']]),
  r('2026-10-15', 'needs_review', 9999, [[9999, 1, 'g']]), // never counts
  r('2026-09-30', 'confirmed', 200, [[200, 1, null]]), // no category -> Uncategorized
  r('2026-10-20', 'confirmed', null, [[50, 3, 'g']]), // no printed total -> items added up
];

describe('dashboard stats', () => {
  it('counts only confirmed receipts and uses the total or the items', () => {
    const s = monthSummary(data, '2026-10', 'Asia/Kathmandu', cats);
    expect(s.total).toBe(1450);
    expect(s.receiptCount).toBe(3);
    expect(s.previousTotal).toBe(200);
  });

  it('splits by category from line items, biggest first', () => {
    const s = monthSummary(data, '2026-10', 'Asia/Kathmandu', cats);
    expect(s.byCategory).toEqual([
      { categoryId: 'g', category: 'Groceries', amount: 1150 },
      { categoryId: 'd', category: 'Food & Dining', amount: 300 },
    ]);
    expect(s.previousByCategory).toEqual([{ categoryId: 'u', category: 'Uncategorized', amount: 200 }]);
  });

  it('gives every day of the month, zeros included', () => {
    const s = monthSummary(data, '2026-10', 'Asia/Kathmandu', cats);
    expect(s.daily).toHaveLength(31);
    expect(s.daily[1].amount).toBe(1300); // 2 Oct
    expect(s.daily[0].amount).toBe(0);
  });

  it('trend: oldest first, zeros included', () => {
    const t = monthlyTotals(data, '2026-10', 3, 'Asia/Kathmandu');
    expect(t.months.map((m) => m.month)).toEqual(['2026-08', '2026-09', '2026-10']);
    expect(t.months.map((m) => m.total)).toEqual([0, 200, 1450]);
  });

  it('spent per category id', () => {
    expect(spentByCategoryId(data, '2026-10', 'Asia/Kathmandu', cats).get('g')).toBe(1150);
  });
});

describe('budget history', () => {
  const history = [
    { categoryId: 'g', effectiveFrom: '2026-08', limit: 5000 },
    { categoryId: 'g', effectiveFrom: '2026-10', limit: 7000 },
    { categoryId: 'd', effectiveFrom: '2026-08', limit: 3000 },
    { categoryId: 'd', effectiveFrom: '2026-10', limit: null }, // removed from October on
  ];
  it('old months keep their old limit', () => {
    expect(limitsInMonth(history, '2026-09').get('g')).toBe(5000);
    expect(limitsInMonth(history, '2026-10').get('g')).toBe(7000);
  });
  it('a null limit means no budget from that month on, earlier months untouched', () => {
    expect(limitsInMonth(history, '2026-09').get('d')).toBe(3000);
    expect(limitsInMonth(history, '2026-10').has('d')).toBe(false);
  });
  it('nothing before the first entry', () => {
    expect(limitsInMonth(history, '2026-07').size).toBe(0);
  });
});

describe('dates', () => {
  it('month maths', () => {
    expect(prevMonth('2026-01')).toBe('2025-12');
    expect(prevMonth('2026-10')).toBe('2026-09');
    expect(daysInMonth('2026-02')).toBe(28);
    expect(daysInMonth('2028-02')).toBe(29);
  });
  it('validation', () => {
    expect(isValidDate('2026-02-30')).toBe(false);
    expect(isValidDate('2026-10-03')).toBe(true);
    expect(isValidMonth('2026-13')).toBe(false);
    expect(daysBetween('2026-10-01', '2026-10-23')).toBe(22);
  });
});
