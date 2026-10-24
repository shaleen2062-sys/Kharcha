import { z } from 'zod';
import { isValidDate, isValidMonth } from '../utils/dates';
import { RECEIPT_STATUSES } from './receipt.model';

const money = z.number().finite().min(0).lt(1e9);

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'Must be a category id');

export const itemSchema = z.object({
  name: z.string().trim().min(1).max(200),
  price: money, // price of ONE unit
  quantity: z.number().int().min(1).max(9999).default(1),
  categoryId: objectId.nullable().optional(),
  /** Convenience: a category NAME, used only when categoryId is not sent. */
  category: z.string().trim().max(50).nullable().optional(),
});

/** PATCH /receipts/:id : the user's corrected receipt. Saving it confirms it. */
export const updateReceiptSchema = z.object({
  status: z.literal('confirmed'),
  merchant: z.string().trim().max(120).nullable().optional(),
  total: money.nullable().optional(),
  currency: z.string().regex(/^[A-Z]{3}$/, 'Must be a 3-letter code like NPR').optional(),
  date: z.string().refine(isValidDate, 'Must look like 2026-10-03').nullable().optional(),
  items: z.array(itemSchema).max(200),
});
export type UpdateReceiptBody = z.infer<typeof updateReceiptSchema>;

export const listReceiptsQuery = z.object({
  status: z.enum(RECEIPT_STATUSES).optional(),
  month: z.string().refine(isValidMonth, 'Must look like 2026-10').optional(),
  limit: z.coerce.number().int().min(1).max(200).default(100),
});

export const idempotencyKey = z.string().regex(/^[A-Za-z0-9_.:-]{1,64}$/, 'The Idempotency-Key header is not valid.');
