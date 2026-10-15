export interface DefaultCategory {
  name: string;
  essential: boolean;
  icon: string;
  color: string;
}

export const DEFAULT_CATEGORIES: DefaultCategory[] = [
  { name: 'Food & Dining',    essential: true,  icon: 'utensils',      color: '#F59E0B' },
  { name: 'Groceries',        essential: true,  icon: 'shopping-cart', color: '#10B981' },
  { name: 'Transport',        essential: true,  icon: 'bus',           color: '#3B82F6' },
  { name: 'Utilities',        essential: true,  icon: 'zap',           color: '#8B5CF6' },
  { name: 'Rent',             essential: true,  icon: 'home',          color: '#EF4444' },
  { name: 'Healthcare',       essential: true,  icon: 'heart-pulse',   color: '#EC4899' },
  { name: 'Education',        essential: true,  icon: 'book-open',     color: '#14B8A6' },
  { name: 'Shopping',         essential: false, icon: 'shopping-bag',  color: '#F97316' },
  { name: 'Entertainment',    essential: false, icon: 'film',          color: '#A855F7' },
  { name: 'Travel',           essential: false, icon: 'plane',         color: '#06B6D4' },
  { name: 'Personal Care',    essential: false, icon: 'sparkles',      color: '#F43F5E' },
  { name: 'Other',            essential: false, icon: 'tag',           color: '#6B7280' },
];

export const FALLBACK_CATEGORY: DefaultCategory = {
  name: 'Uncategorized',
  essential: false,
  icon: 'help-circle',
  color: '#9CA3AF',
};
