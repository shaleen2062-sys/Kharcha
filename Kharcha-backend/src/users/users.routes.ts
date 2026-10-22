import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.middleware';
import { asyncHandler } from '../utils/asyncHandler';
import { validate } from '../middleware/validate';
import { ApiError } from '../utils/ApiError';
import { CURRENCIES } from './user.model';
import { getUser, updateUser, softDeleteUser } from './users.service';

const router = Router();

router.use(requireAuth);

router.get(
  '/me',
  asyncHandler(async (req, res) => {
    const user = await getUser(req.user!.id);
    if (!user) throw ApiError.notFound('User');
    res.json({ user });
  }),
);

const updateSchema = z.object({
  name: z.string().trim().min(1).max(80).optional(),
  photoUrl: z.string().url().nullable().optional(),
  currency: z.enum(CURRENCIES).optional(),
  aiEnabled: z.boolean().optional(),
  onboardingCompleted: z.boolean().optional(),
});

router.patch(
  '/me',
  validate({ body: updateSchema }),
  asyncHandler(async (req, res) => {
    const updated = await updateUser(req.user!.id, req.body);
    if (!updated) throw ApiError.notFound('User');
    res.json({ user: updated });
  }),
);

router.delete(
  '/me',
  asyncHandler(async (req, res) => {
    await softDeleteUser(req.user!.id);
    res.status(204).send();
  }),
);

export default router;