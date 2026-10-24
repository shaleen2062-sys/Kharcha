import { Schema, model, InferSchemaType, HydratedDocument } from 'mongoose';

export const RECEIPT_STATUSES = ['processing', 'needs_review', 'confirmed', 'failed'] as const;
export type ReceiptStatus = (typeof RECEIPT_STATUSES)[number];

const itemSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 200 },
    price: { type: Number, required: true, min: 0 }, // price of ONE unit
    quantity: { type: Number, default: 1, min: 1 },
    categoryId: { type: Schema.Types.ObjectId, ref: 'Category', default: null },
    // What the AI suggested, kept so a user's correction can be learned from.
    aiCategoryId: { type: Schema.Types.ObjectId, ref: 'Category', default: null },
  },
  { _id: false },
);

const receiptSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status: { type: String, enum: RECEIPT_STATUSES, default: 'processing' },
    merchant: { type: String, default: null, trim: true, maxlength: 120 },
    total: { type: Number, default: null, min: 0 },
    tax: { type: Number, default: null, min: 0 },
    discount: { type: Number, default: null, min: 0 },
    cashPaid: { type: Number, default: null, min: 0 },
    change: { type: Number, default: null, min: 0 },
    currency: { type: String, default: 'NPR' },
    date: { type: String, default: null }, // YYYY-MM-DD, no time zone
    items: { type: [itemSchema], default: [] },
    imagePath: { type: String, default: null }, // name inside the storage
    idempotencyKey: { type: String, default: undefined },
    confidence: { type: Number, default: null, min: 0, max: 1 },
    confidenceReason: { type: String, default: null, maxlength: 500 },
    reviewReasons: { type: [String], default: [] },
    source: { type: String, enum: ['ai', 'manual'], default: 'ai' },
    deletedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform(_doc, ret: Record<string, unknown>) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        delete ret.deletedAt;
        delete ret.idempotencyKey;
        return ret;
      },
    },
  },
);

receiptSchema.index({ userId: 1, createdAt: -1 });
receiptSchema.index({ userId: 1, status: 1, date: 1 });
// One receipt per (user, key). Only receipts that have a key take part.
receiptSchema.index(
  { userId: 1, idempotencyKey: 1 },
  { unique: true, partialFilterExpression: { idempotencyKey: { $type: 'string' } } },
);

export type ReceiptDoc = HydratedDocument<InferSchemaType<typeof receiptSchema>>;
export const Receipt = model('Receipt', receiptSchema);
