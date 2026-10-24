import { Express } from 'express';
import usersRouter from './users/users.routes';
import categoriesRouter from './categories/categories.routes';
import receiptsRouter from './receipts/receipts.routes';
import budgetsRouter from './budgets/budgets.routes';
import alertsRouter from './alerts/alerts.routes';
import dashboardRouter from './dashboard/dashboard.routes';
import filesRouter from './files/files.routes';

export function mountRoutes(app: Express): void {
  app.use('/api/users', usersRouter);
  app.use('/api/categories', categoriesRouter);
  app.use('/api/receipts', receiptsRouter);
  app.use('/api/budgets', budgetsRouter);
  app.use('/api/alerts', alertsRouter);
  app.use('/api/dashboard', dashboardRouter);
  // Signed photo links (STORAGE_MODE=local). No login header: the link itself is the proof.
  app.use('/files', filesRouter);
}