import 'express';

export interface AuthUser {
  id: string;    // Mongo ObjectId 
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
