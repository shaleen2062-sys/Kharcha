/**
 * The reader (../reader) labels every item with one of eight categories. Kharcha's categories are
 * per user and richer, so this maps between them. The keyword rules are only a FALLBACK for when the
 * reader says nothing usable (they are rules, not AI).
 */
export const READER_TO_KHARCHA: Record<string, string> = {
  Groceries: 'Groceries',
  Dining: 'Food & Dining',
  Transport: 'Transport',
  Shopping: 'Shopping',
  Health: 'Healthcare',
  Bills: 'Utilities',
  Entertainment: 'Entertainment',
  Other: 'Other',
};

const PERSONAL_CARE = ['face wash', 'shampoo', 'soap', 'lotion', 'toothpaste', 'conditioner', 'deodorant', 'साबुन'];

const RULES: Array<[string, string[]]> = [
  ['Healthcare', ['pharmacy', 'medicine', 'tablet', 'vitamin', 'syrup', 'clinic', 'hospital', 'औषधि', 'फार्मेसी']],
  ['Personal Care', ['face wash', 'shampoo', 'soap', 'lotion', 'cream', 'toothpaste', 'साबुन']],
  ['Transport', ['petrol', 'diesel', 'fuel', 'taxi', 'uber', 'pathao', 'parking', 'toll', 'पेट्रोल', 'डिजेल']],
  ['Utilities', ['electricity', 'internet', 'wifi', 'recharge', 'top-up', 'topup', 'ntc', 'ncell', 'nea', 'बिजुली']],
  ['Rent', ['rent', 'भाडा']],
  ['Entertainment', ['movie', 'cinema', 'ticket', 'netflix', 'game', 'concert', 'popcorn']],
  ['Food & Dining', ['restaurant', 'cafe', 'coffee', 'momo', 'thali', 'burger', 'pizza', 'chowmein', 'noodle', 'juice', 'lassi', 'beer', 'service charge', 'मोमो', 'थाली', 'चाउमिन', 'कफी', 'खाना']],
  ['Groceries', ['rice', 'dal', 'lentil', 'oil', 'milk', 'egg', 'vegetable', 'fruit', 'bread', 'atta', 'flour', 'sugar', 'salt', 'tea', 'butter', 'dairy', 'snack', 'चामल', 'दाल', 'तेल', 'दूध', 'अण्डा', 'तरकारी', 'फलफूल', 'आटा', 'चिनी', 'नुन']],
  ['Shopping', ['detergent', 'shirt', 'shoes', 'earphone', 'cable', 'bag', 'clothes', 'लुगा']],
];

/** Kharcha category NAME for an item: the reader's label if it is one we know, else keyword rules, else null. */
export function categoryNameFor(readerLabel: string | null | undefined, itemName: string): string | null {
  // The reader has no "Personal Care" label: its Health/Shopping/Other guess for soap or shampoo is overridden.
  if (!readerLabel || ['Health', 'Shopping', 'Other'].includes(readerLabel)) {
    const text = ` ${itemName.toLowerCase()} `;
    if (PERSONAL_CARE.some((w) => text.includes(w))) return 'Personal Care';
  }
  if (readerLabel && READER_TO_KHARCHA[readerLabel] && readerLabel !== 'Other') {
    return READER_TO_KHARCHA[readerLabel];
  }
  const text = ` ${itemName.toLowerCase()} `;
  for (const [category, words] of RULES) {
    if (words.some((w) => text.includes(w))) return category;
  }
  return readerLabel && READER_TO_KHARCHA[readerLabel] ? READER_TO_KHARCHA[readerLabel] : null;
}
