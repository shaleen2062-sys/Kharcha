import express from 'express';
import multer from 'multer';
import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';
import { ApiError } from '../utils/ApiError';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: env.MAX_UPLOAD_MB * 1024 * 1024, files: 1 },
}).single('image');

const rawUpload = express.raw({
  type: ['image/jpeg', 'application/octet-stream'],
  limit: env.MAX_UPLOAD_MB * 1024 * 1024,
});

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

/** Reads a raw JPEG body for mobile clients that have trouble completing multipart uploads. */
export function receiveRawImage(req: Request, res: Response, next: NextFunction): void {
  rawUpload(req, res, (err: unknown) => {
    if (err) return next(new ApiError(400, 'Send the JPEG photo as the request body.', 'INVALID_UPLOAD'));
    if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
      return next(new ApiError(400, 'Send the JPEG photo as the request body.', 'INVALID_UPLOAD'));
    }
    next();
  });
}
