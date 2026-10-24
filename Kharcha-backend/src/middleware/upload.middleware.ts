import multer from 'multer';
import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';
import { ApiError } from '../utils/ApiError';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: env.MAX_UPLOAD_MB * 1024 * 1024, files: 1 },
}).single('image');

/** Reads one photo from the multipart field "image" into req.file, with friendly errors. */
export function receiveImage(req: Request, res: Response, next: NextFunction): void {
  upload(req, res, (err: unknown) => {
    if (!err) return next();
    if ((err as { code?: string }).code === 'LIMIT_FILE_SIZE') {
      return next(new ApiError(413, 'The photo is too large to upload.', 'FILE_TOO_LARGE'));
    }
    return next(ApiError.badRequest('Send one photo in the "image" field.'));
  });
}
