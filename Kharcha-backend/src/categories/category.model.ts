import { Schema, model, InferSchemaType, HydratedDocument, Types } from 'mongoose';

const categorySchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, trim: true, maxlength: 50 },
    essential: { type: Boolean, default: false },
    icon: { type: String, default: 'tag' },
    color: { type: String, default: null },
    isFallback: { type: Boolean, default: false },
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

categorySchema.index({ userId: 1, name: 1 }, { unique: true });
categorySchema.index({ userId: 1, deletedAt: 1 });
categorySchema.index(
  { userId: 1, isFallback: 1 },
  { unique: true, partialFilterExpression: { isFallback: true } },
);

export type CategoryDoc = HydratedDocument<InferSchemaType<typeof categorySchema>>;
export type CategoryId = Types.ObjectId;
export const Category = model('Category', categorySchema);
