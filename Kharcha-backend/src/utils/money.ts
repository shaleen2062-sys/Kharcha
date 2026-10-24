export const round2 = (n: number): number => Math.round((n + Number.EPSILON) * 100) / 100;

export interface PricedItem {
  price: number; // price of ONE unit
  quantity?: number | null;
}

export const itemsSum = (items: PricedItem[]): number =>
  items.reduce((s, i) => s + i.price * (i.quantity || 1), 0);
