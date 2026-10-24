import { Schema, model, InferSchemaType, HydratedDocument } from 'mongoose';

/**
 * One row per automatic step taken on a receipt (reading, validating, learning).
 * This is the audit trail behind "delete the AI": every AI decision can be seen, and the app
 * works without any of them (READER=manual).
 */
const agentRunSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    receiptId: { type: Schema.Types.ObjectId, ref: 'Receipt', required: true, index: true },
    agent: { type: String, enum: ['reader', 'validation', 'alerts'], required: true },
    ok: { type: Boolean, required: true },
    durationMs: { type: Number, default: 0 },
    summary: { type: Schema.Types.Mixed, default: {} },
    error: { type: String, default: null },
  },
  { timestamps: true },
);

agentRunSchema.index({ receiptId: 1, createdAt: 1 });

export type AgentRunDoc = HydratedDocument<InferSchemaType<typeof agentRunSchema>>;
export const AgentRun = model('AgentRun', agentRunSchema);
