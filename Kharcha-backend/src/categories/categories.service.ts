import { Types } from 'mongoose';
import { Category, CategoryDoc, CategoryId } from './category.model';
import { DEFAULT_CATEGORIES, FALLBACK_CATEGORY, DefaultCategory } from './defaultCategories';
import { ApiError } from '../utils/ApiError';
import { logger } from '../utils/logger';

export async function seedDefaultCategories(userId: Types.ObjectId): Promise<void> {
  const existing = await Category.countDocuments({ userId });
  if (existing > 0) {
    logger.debug({ userId }, 'Categories already seeded, skipping');
    return;
  }

  const docs = [
    ...DEFAULT_CATEGORIES.map((c) => ({ ...c, userId, isFallback: false })),
    { ...FALLBACK_CATEGORY, userId, isFallback: true },
  ];

  try {
    await Category.insertMany(docs, { ordered: false });
    logger.info({ userId, count: docs.length }, 'Seeded default categories');
  } catch (err: unknown) {
    if ((err as { code?: number }).code === 11000) {
      logger.debug({ userId }, 'Seed raced with another request, ignoring');
      return;
    }
    throw err;
  }
}

export async function findOrCreateCategory(
  userId: Types.ObjectId,
  name: string,
  options: { essential?: boolean; icon?: string; color?: string } = {},
): Promise<CategoryDoc> {
  const trimmed = name.trim();
  if (!trimmed) throw ApiError.badRequest('Category name is required');

  const escaped = trimmed.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const existing = await Category.findOne({
    userId,
    name: { $regex: `^${escaped}$`, $options: 'i' },
    deletedAt: null,
  });
  if (existing) return existing;

  return Category.create({
    userId,
    name: trimmed,
    essential: options.essential ?? false,
    icon: options.icon ?? 'tag',
    color: options.color ?? null,
  });
}

export function listCategories(userId: Types.ObjectId) {
  return Category.find({ userId, deletedAt: null }).sort({ isFallback: 1, name: 1 });
}

export async function getCategoryById(
  userId: Types.ObjectId,
  id: string | CategoryId,
): Promise<CategoryDoc> {
  if (!Types.ObjectId.isValid(id)) throw ApiError.notFound('Category');
  const cat = await Category.findOne({ _id: id, userId, deletedAt: null });
  if (!cat) throw ApiError.notFound('Category');
  return cat;
}

export async function updateCategory(
  userId: Types.ObjectId,
  id: string | CategoryId,
  patch: Partial<Pick<DefaultCategory, 'name' | 'icon' | 'color' | 'essential'>>,
) {
  const cat = await getCategoryById(userId, id);

  if (cat.isFallback && patch.name) {
    throw ApiError.badRequest('Cannot rename the fallback category');
  }

  if (patch.name !== undefined) cat.name = patch.name.trim();
  if (patch.icon !== undefined) cat.icon = patch.icon;
  if (patch.color !== undefined) cat.color = patch.color;
  if (patch.essential !== undefined) cat.essential = patch.essential;

  await cat.save();
  return cat;
}

export async function deleteCategory(
  userId: Types.ObjectId,
  id: string | CategoryId,
): Promise<void> {
  const cat = await getCategoryById(userId, id);

  if (cat.isFallback) {
    throw ApiError.badRequest('Cannot delete the fallback category');
  }

  cat.deletedAt = new Date();
  await cat.save();
  logger.info({ userId, categoryId: id }, 'Category soft-deleted');
}

export async function getFallbackCategory(userId: Types.ObjectId) {
  const cat = await Category.findOne({ userId, isFallback: true, deletedAt: null });
  if (!cat) throw ApiError.internal('Fallback category missing for user');
  return cat;
}