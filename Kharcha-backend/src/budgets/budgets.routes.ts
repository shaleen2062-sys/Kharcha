import { Router } from 'express';
import { Types } from 'mongoose';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.middleware';
import { asyncHandler } from '../utils/asyncHandler';
import { validate } from '../middleware/validate';
import { isValidMonth } from '../utils/dates';
import { listBudgets, setBudget, removeBudget } from './budgets.service';

const router = Router();
router.use(requireAuth);

const month = z.string().refine(isValidMonth, 'Must look like 2026-10');

// GET /budgets?month=2026-10
router.get(
  '/',
  validate({ query: z.object({ month: month.optional() }) }),
  asyncHandler(async (req, res) => {
    const budgets = await listBudgets(new Types.ObjectId(req.user!.id), req.query.month as string | undefined);
    res.json({ budgets });
  }),
);

// PUT /budgets/:categoryId   { limit, effectiveFrom? }
router.put(
  '/:categoryId',
  validate({ body: z.object({ limit: z.number().positive().lt(1e9), effectiveFrom: month.optional() }) }),
  asyncHandler(async (req, res) => {
    const budget = await setBudget(
      new Types.ObjectId(req.user!.id),
      String(req.params.categoryId),
      req.body.limit,
      req.body.effectiveFrom,
    );
    res.json({ budget });
  }),
);

// DELETE /budgets/:categoryId?effectiveFrom=2026-10
router.delete(
  '/:categoryId',
  validate({ query: z.object({ effectiveFrom: month.optional() }) }),
  asyncHandler(async (req, res) => {
    await removeBudget(
      new Types.ObjectId(req.user!.id),
      String(req.params.categoryId),
      req.query.effectiveFrom as string | undefined,
    );
    res.status(204).send();
  }),
);

export default router;
