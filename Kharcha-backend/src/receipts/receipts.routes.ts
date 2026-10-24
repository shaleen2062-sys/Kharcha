import { Router } from 'express';
import { Types } from 'mongoose';
import { requireAuth } from '../middleware/auth.middleware';
import { receiveImage } from '../middleware/upload.middleware';
import { asyncHandler } from '../utils/asyncHandler';
import { validate } from '../middleware/validate';
import { ApiError } from '../utils/ApiError';
import { updateReceiptSchema, listReceiptsQuery } from './receipts.schemas';
import {
  createFromUpload,
  listReceipts,
  getReceipt,
  confirmReceipt,
  deleteReceipt,
  presentOne,
  presentMany,
} from './receipts.service';

const router = Router();
router.use(requireAuth);

const uid = (req: Express.Request): Types.ObjectId => new Types.ObjectId(req.user!.id);

// POST /receipts   multipart field "image" (JPEG), optional Idempotency-Key header
// 202 = accepted, being read in the background; 200 = same Idempotency-Key as an earlier upload
router.post(
  '/',
  receiveImage,
  asyncHandler(async (req, res) => {
    if (!req.file) throw ApiError.badRequest('Send one photo in the "image" field.');
    const { receipt, created } = await createFromUpload(uid(req), {
      buffer: req.file.buffer,
      idempotencyKey: req.get('Idempotency-Key') || undefined,
    });
    res.status(created ? 202 : 200).json({ receipt: await presentOne(uid(req), receipt) });
  }),
);

// GET /receipts?status=&month=&limit=
router.get(
  '/',
  validate({ query: listReceiptsQuery }),
  asyncHandler(async (req, res) => {
    const q = req.query as unknown as { status?: string; month?: string; limit: number };
    res.json({ receipts: await presentMany(uid(req), await listReceipts(uid(req), q)) });
  }),
);

// GET /receipts/:id
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json({ receipt: await presentOne(uid(req), await getReceipt(uid(req), String(req.params.id))) });
  }),
);

// PATCH /receipts/:id   the user's corrections; saving confirms the receipt
router.patch(
  '/:id',
  validate({ body: updateReceiptSchema }),
  asyncHandler(async (req, res) => {
    const r = await confirmReceipt(uid(req), String(req.params.id), req.body);
    res.json({ receipt: await presentOne(uid(req), r) });
  }),
);

// DELETE /receipts/:id
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    await deleteReceipt(uid(req), String(req.params.id));
    res.status(204).send();
  }),
);

export default router;
