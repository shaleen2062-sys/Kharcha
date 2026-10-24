import { Schema, model, InferSchemaType, HydratedDocument } from 'mongoose';

/**
 * A budget is a HISTORY: one document per (user, category, effectiveFrom month).
 * `limit: null` means "no budget from this month on". For month M the limit in force is the
 * document with the latest effectiveFrom <= M. Changing a limit adds a document; old months keep theirs.
 */
const budgetSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    categoryId: { type: Schema.Types.ObjectId, ref: 'Category', required: true },
    effectiveFrom: { type: String, required: true }, // YYYY-MM
    limit: { type: Number, default: null, min: 0 },
  },
  { timestamps: true },
);

budgetSchema.index({ userId: 1, categoryId: 1, effectiveFrom: 1 }, { unique: true });

export type BudgetDoc = HydratedDocument<InferSchemaType<typeof budgetSchema>>;
export const Budget = model('Budget', budgetSchema);
