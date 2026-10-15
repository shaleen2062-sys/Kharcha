import 'express';

/**
 * Shape of `req.user` after `requireAuth` middleware runs.
 * Set by src/middleware/auth.middleware.ts.
 */
export interface AuthUser {
  id: string;    // Mongo ObjectId (User._id, as string)
  uid: string;   // Firebase UID
  email?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}
