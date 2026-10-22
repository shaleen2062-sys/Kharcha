import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { ApiError } from '../utils/ApiError';
import { logger } from '../utils/logger';
import { env } from '../config/env';


export function errorHandler(
  err: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
) {

  if (err instanceof ApiError) {
    if (err.status >= 500) {
      logger.error({ err, path: req.path }, err.message);
    }
    return res.status(err.status).json({
      error: {
        code: err.code,
        message: err.message,
        ...(err.details ? { details: err.details } : {}),
      },
    });
  }

  if (err instanceof ZodError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: err.flatten().fieldErrors,
      },
    });
  }

  if (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    (err as { code: number }).code === 11000
  ) {
    return res.status(409).json({
      error: { code: 'DUPLICATE_KEY', message: 'Resource already exists' },
    });
  }

  const message = err instanceof Error ? err.message : 'Unknown error';
  logger.error({ err, path: req.path, method: req.method }, `Unhandled error: ${message}`);

  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: env.NODE_ENV === 'production' ? 'Internal server error' : message,
    },
  });
}

export function notFoundHandler(req: Request, _res: Response, next: NextFunction) {
  next(ApiError.notFound(`Route ${req.method} ${req.path}`));
}
