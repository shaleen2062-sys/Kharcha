import { Schema, model, InferSchemaType, HydratedDocument } from 'mongoose';

export const ALERT_TYPES = ['budget_warning', 'budget_exceeded', 'possible_duplicate', 'needs_review'] as const;
export type AlertType = (typeof ALERT_TYPES)[number];

const alertSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ALERT_TYPES, required: true },
    // One alert per (user, type, subject): subject is "<categoryId>:<month>" for budgets, the receipt id otherwise.
    subject: { type: String, required: true },
    categoryId: { type: Schema.Types.ObjectId, ref: 'Category', default: null },
    receiptId: { type: Schema.Types.ObjectId, ref: 'Receipt', default: null },
    month: { type: String, default: null },
    percent: { type: Number, default: null },
    message: { type: String, required: true },
    readAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform(_doc, ret: Record<string, unknown>) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        delete ret.subject;
        return ret;
      },
    },
  },
);

alertSchema.index({ userId: 1, type: 1, subject: 1 }, { unique: true });
alertSchema.index({ userId: 1, createdAt: -1 });

export type AlertDoc = HydratedDocument<InferSchemaType<typeof alertSchema>>;
export const Alert = model('Alert', alertSchema);
