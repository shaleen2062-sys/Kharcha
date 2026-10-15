import { cert, getApps, initializeApp, App } from 'firebase-admin/app';
import { getAuth, Auth, DecodedIdToken } from 'firebase-admin/auth';
import { env } from './env';
import { ApiError } from '../utils/ApiError';

let firebaseApp: App | null = null;
let firebaseAuth: Auth | null = null;

function initFirebase(): App {
  if (firebaseApp) return firebaseApp;

  if (
    !env.FIREBASE_PROJECT_ID ||
    !env.FIREBASE_CLIENT_EMAIL ||
    !env.FIREBASE_PRIVATE_KEY
  ) {
    throw new Error(
      'Firebase credentials missing. Set FIREBASE_PROJECT_ID, ' +
      'FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY in .env',
    );
  }

  const existing = getApps();
  firebaseApp = existing.length > 0
    ? existing[0]
    : initializeApp({
        credential: cert({
          projectId: env.FIREBASE_PROJECT_ID,
          clientEmail: env.FIREBASE_CLIENT_EMAIL,
          privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });

  return firebaseApp;
}

export function getFirebaseAuth(): Auth {
  if (env.AUTH_MODE !== 'firebase') {
    throw ApiError.internal('Firebase auth requested but AUTH_MODE is not "firebase"');
  }

  if (firebaseAuth) return firebaseAuth;

  const app = initFirebase();
  firebaseAuth = getAuth(app);
  return firebaseAuth;
}

export async function verifyFirebaseToken(idToken: string): Promise<DecodedIdToken> {
  try {
    const auth = getFirebaseAuth();
    return await auth.verifyIdToken(idToken);
  } catch (err: any) {
    switch (err?.code) {
      case 'auth/id-token-expired':
        throw ApiError.unauthorized('Token expired');
      case 'auth/id-token-revoked':
        throw ApiError.unauthorized('Token revoked');
      case 'auth/argument-error':
        throw ApiError.unauthorized('Invalid token');
      case 'auth/user-disabled':
        throw ApiError.unauthorized('User disabled');
      default:
        throw ApiError.unauthorized('Invalid or expired token');
    }
  }
}