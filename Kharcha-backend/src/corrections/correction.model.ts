import { Schema, model } from 'mongoose';

/** "When I fix 'tea' to Groceries, remember it." One row per (user, item name). */
const correctionSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    key: { type: String, required: true }, // normalized item name
    categoryId: { type: Schema.Types.ObjectId, ref: 'Category', required: true },
    count: { type: Number, default: 1 },
  },
  { timestamps: true },
);

correctionSchema.index({ userId: 1, key: 1 }, { unique: true });

export const Correction = model('Correction', correctionSchema);
