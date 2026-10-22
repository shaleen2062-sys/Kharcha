import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';
import { verifyFirebaseToken } from '../config/firebase';
import { ApiError } from '../utils/ApiError';
import { asyncHandler } from '../utils/asyncHandler';
import { logger } from '../utils/logger';
import { getOrCreateUser } from '../users/users.service';

export const requireAuth = asyncHandler(
  async (req: Request, _res: Response, next: NextFunction) => {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Missing Bearer token');
    }

    const token = header.slice(7).trim();
    if (!token) throw ApiError.unauthorized('Empty token');

    let uid: string;
    let email: string | undefined;
    let name: string | undefined;

    if (env.AUTH_MODE === 'dev') {
      if (!token.startsWith('dev:')) {
        throw ApiError.unauthorized('Dev mode requires "Bearer dev:<uid>"');
      }
      uid = token.slice(4).trim();
      if (!uid) throw ApiError.unauthorized('Dev token missing uid');
      logger.debug({ uid }, 'Auth (dev)');
    } else {
      // Firebase mode
      try {
        const decoded = await verifyFirebaseToken(token);
        uid = decoded.uid;
        email = decoded.email;
        name = (decoded as { name?: string }).name;
      } catch (err) {
        logger.warn({ err }, 'Firebase token verification failed');
        throw ApiError.unauthorized('Invalid or expired token');
      }
    }
    const user = await getOrCreateUser(uid, email, name);
    req.user = { id: String(user._id), uid, email };
    next();
  },
);
