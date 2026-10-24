import { Router } from 'express';
import { Types } from 'mongoose';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.middleware';
import { asyncHandler } from '../utils/asyncHandler';
import { validate } from '../middleware/validate';
import { listAlerts, markRead, markAllRead } from './alerts.service';

const router = Router();
router.use(requireAuth);

const listQuery = z.object({ unread: z.enum(['true', 'false']).optional() });

// GET /alerts?unread=true
router.get(
  '/',
  validate({ query: listQuery }),
  asyncHandler(async (req, res) => {
    const userId = new Types.ObjectId(req.user!.id);
    res.json(await listAlerts(userId, req.query.unread === 'true'));
  }),
);

// POST /alerts/read-all   (declared before /:id/read so "read-all" is not taken as an id)
router.post(
  '/read-all',
  asyncHandler(async (req, res) => {
    await markAllRead(new Types.ObjectId(req.user!.id));
    res.status(204).send();
  }),
);

// POST /alerts/:id/read
router.post(
  '/:id/read',
  asyncHandler(async (req, res) => {
    const alert = await markRead(new Types.ObjectId(req.user!.id), String(req.params.id));
    res.json({ alert });
  }),
);

export default router;
