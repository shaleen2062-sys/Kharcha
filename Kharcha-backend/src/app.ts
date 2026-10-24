import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { env } from './config/env';
import { mountRoutes } from './routes';
import { errorHandler, notFoundHandler } from './middleware/error.middleware';

export function createApp() {
  const app = express();

  app.use(helmet());

  app.use(
    cors({
      origin: env.NODE_ENV === 'production' ? env.CORS_ORIGINS : true,
      credentials: true,
    }),
  );

  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));

  app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', env: env.NODE_ENV });
  });

  mountRoutes(app);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}