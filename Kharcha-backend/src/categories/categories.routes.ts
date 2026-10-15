import { Router } from 'express';
import { z } from 'zod';
import { Types } from 'mongoose';
import { requireAuth } from '../middleware/auth.middleware';
import { asyncHandler } from '../utils/asyncHandler';
import { validate } from '../middleware/validate';
import { ApiError } from '../utils/ApiError';
import {
  listCategories,
  findOrCreateCategory,
  updateCategory,
  deleteCategory,
} from './categories.service';

const router = Router();

router.use(requireAuth);

//GET /categories 
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const userId = new Types.ObjectId(req.user!.id);
    const categories = await listCategories(userId);
    res.json({ categories });
  }),
);

//POST /categories
const createSchema = z.object({
  name: z.string().trim().min(1).max(50),
  essential: z.boolean().optional(),
  icon: z.string().trim().max(30).optional(),
  color: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/, 'Must be a hex color like #F59E0B')
    .optional(),
});

router.post(
  '/',
  validate({ body: createSchema }),
  asyncHandler(async (req, res) => {
    const userId = new Types.ObjectId(req.user!.id);
    const cat = await findOrCreateCategory(userId, req.body.name, {
      essential: req.body.essential,
      icon: req.body.icon,
      color: req.body.color,
    });
    res.status(201).json({ category: cat });
  }),
);

// PATCH /categories/:id
const updateSchema = createSchema.partial();

router.patch(
  '/:id',
  validate({ body: updateSchema }),
  asyncHandler(async (req, res) => {
    if (!Types.ObjectId.isValid(req.params.id)) throw ApiError.notFound('Category');
    const userId = new Types.ObjectId(req.user!.id);
    const cat = await updateCategory(userId, req.params.id, req.body);
    res.json({ category: cat });
  }),
);

//DELETE /categories/:id 
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    if (!Types.ObjectId.isValid(req.params.id)) throw ApiError.notFound('Category');
    const userId = new Types.ObjectId(req.user!.id);
    await deleteCategory(userId, req.params.id);
    res.status(204).send();
  }),
);

export default router;
