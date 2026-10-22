import { createApp } from './app';
import { connectDB, disconnectDB } from './config/db';
import { env } from './config/env';
import { logger } from './utils/logger';
import { getFirebaseAuth } from './config/firebase';

async function start() {
  await connectDB();

  try {
    getFirebaseAuth();
    logger.info('Firebase Admin initialized');
  } catch (err: any) {
    logger.error({ err }, 'Firebase Admin failed to initialize');
    process.exit(1);
  }

  const app = createApp();

  const server = app.listen(env.PORT, () => {
    logger.info(`Kharcha API listening on http://localhost:${env.PORT}`);
    logger.info(`ENV: ${env.NODE_ENV} | AUTH_MODE: ${env.AUTH_MODE}`);
    logger.info(`Health: http://localhost:${env.PORT}/health`);
  });

  const shutdown = async (signal: string) => {
    logger.info(`Received ${signal}, shutting down...`);
    server.close(async () => {
      await disconnectDB();
      logger.info('Server shut down');
      process.exit(0);
    });
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));

  process.on('unhandledRejection', (reason) => {
    logger.error({ reason }, 'Unhandled promise rejection');
  });

  process.on('uncaughtException', (err) => {
    logger.error({ err }, 'Uncaught exception - exiting');
    process.exit(1);
  });
}

start().catch((err) => {
  logger.error({ err }, 'Failed to start server');
  process.exit(1);
});