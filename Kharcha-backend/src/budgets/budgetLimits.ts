export interface BudgetEntry {
  categoryId: string;
  effectiveFrom: string; // YYYY-MM
  limit: number | null; // null = no budget from that month on
}

/**
 * For month M and each category, the entry with the latest effectiveFrom <= M wins;
 * a null limit means "no budget". Returns categoryId -> limit for the budgets in force.
 */
export function limitsInMonth(history: BudgetEntry[], month: string): Map<string, number> {
  const best = new Map<string, BudgetEntry>();
  for (const h of history) {
    if (h.effectiveFrom > month) continue;
    const cur = best.get(h.categoryId);
    if (!cur || h.effectiveFrom > cur.effectiveFrom) best.set(h.categoryId, h);
  }
  const out = new Map<string, number>();
  for (const [id, h] of best) if (h.limit != null) out.set(id, h.limit);
  return out;
}
