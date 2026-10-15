import { Express } from 'express';
import usersRouter from './users/users.routes';
import categoriesRouter from './categories/categories.routes';

export function mountRoutes(app: Express): void {
  app.use('/api/users', usersRouter);
  app.use('/api/categories', categoriesRouter);
}