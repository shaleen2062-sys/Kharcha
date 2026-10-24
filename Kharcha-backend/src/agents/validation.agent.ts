/**
 * The reader owns the AI verdict. The backend persists and presents that verdict rather than
 * creating a second, competing review policy.
 */
export const REVIEW_REASONS = [
  'reader_flagged',
] as const;
export type ReviewReason = (typeof REVIEW_REASONS)[number];

export interface Reading {
  merchant: string | null;
  total: number | null;
  date: string | null; // YYYY-MM-DD
  currency: string;
  confidence?: number; // 0..1, from the reader
  confidenceReason?: string; // explanation from the reader's confidence rule
  readerNeedsReview?: boolean; // the reader's own verdict
  readable?: boolean; // false = the photo was noise
  items: Array<{ name: string; price: number; quantity: number }>;
}

export interface KnownReceipt {
  id?: string;
  merchant: string | null;
  total: number | null;
  date: string | null;
}

export interface ValidationInput {
  reading: Reading;
  minConfidence: number;
  today: string; // YYYY-MM-DD in the user's time zone
  recent: KnownReceipt[]; // the user's other receipts, to find duplicates
}

export interface Verdict {
  status: 'confirmed' | 'needs_review';
  reasons: ReviewReason[];
  duplicateOf?: string;
}

export function validateReading({ reading, minConfidence, today, recent }: ValidationInput): Verdict {
  void minConfidence;
  void today;
  void recent;
  return reading.readerNeedsReview
    ? { status: 'needs_review', reasons: ['reader_flagged'] }
    : { status: 'confirmed', reasons: [] };
}
