import { Schema, model, InferSchemaType, HydratedDocument } from 'mongoose';

export const CURRENCIES = ['NPR', 'USD', 'INR', 'EUR'] as const;
export type Currency = (typeof CURRENCIES)[number];

const userSchema = new Schema(
  {
    uid: { type: String, required: true, unique: true, index: true, trim: true },
    email: { type: String, lowercase: true, trim: true, index: true },
    name: { type: String, trim: true, default: '' },
    photoUrl: { type: String, default: null },
    currency: { type: String, enum: CURRENCIES, default: 'NPR' },
    aiEnabled: { type: Boolean, default: true },
    onboardingCompleted: { type: Boolean, default: false },
    // Added for budgets/alerts: warn when a category reaches this % of its limit
    alertPercent: { type: Number, min: 50, max: 100, default: 80 },
    notificationsEnabled: { type: Boolean, default: true },
    monthlyIncome: { type: Number, min: 0, default: null },
    totalBudget: { type: Number, min: 0, default: null },
    lastLoginAt: { type: Date, default: null },
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
        return ret;
      },
    },
  },
);

userSchema.index({ uid: 1, deletedAt: 1 });

export type UserDoc = HydratedDocument<InferSchemaType<typeof userSchema>>;
export const User = model('User', userSchema);
