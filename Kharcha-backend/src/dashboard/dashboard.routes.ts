import { Router } from 'express';
import { Types } from 'mongoose';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.middleware';
import { asyncHandler } from '../utils/asyncHandler';
import { validate } from '../middleware/validate';
import { isValidMonth } from '../utils/dates';
import { summary, trend } from './dashboard.service';

const router = Router();
router.use(requireAuth);

const month = z.string().refine(isValidMonth, 'Must look like 2026-10');

// GET /dashboard/summary?month=2026-10
router.get(
  '/summary',
  validate({ query: z.object({ month: month.optional() }) }),
  asyncHandler(async (req, res) => {
    res.json({ summary: await summary(new Types.ObjectId(req.user!.id), req.query.month as string | undefined) });
  }),
);

// GET /dashboard/trend?months=6&month=2026-10
router.get(
  '/trend',
  validate({ query: z.object({ months: z.coerce.number().int().min(2).max(24).optional(), month: month.optional() }) }),
  asyncHandler(async (req, res) => {
    const months = req.query.months as unknown as number | undefined;
    res.json({ trend: await trend(new Types.ObjectId(req.user!.id), months, req.query.month as string | undefined) });
  }),
);

export default router;
