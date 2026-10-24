import { Router } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { getStorage, isSafeName, signer } from '../storage/storage';
import { ApiError } from '../utils/ApiError';

/**
 * GET /files/<name>?exp=...&sig=...
 * Serves a receipt photo to anyone holding a valid, unexpired signed link.
 * Only used with STORAGE_MODE=local (or memory); Supabase hands out its own signed links.
 */
const router = Router();

router.get(
  '/:name',
  asyncHandler(async (req, res) => {
    const name = String(req.params.name);
    if (!isSafeName(name) || !signer.verify(name, req.query.exp, req.query.sig)) {
      throw ApiError.forbidden('This link is not valid or has expired.');
    }
    let buffer: Buffer;
    try {
      buffer = await getStorage().read(name);
    } catch {
      throw ApiError.notFound('Photo');
    }
    res.set('Cache-Control', 'private, max-age=300');
    res.type('image/jpeg').send(buffer);
  }),
);

export default router;
