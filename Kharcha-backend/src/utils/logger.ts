
import { env } from '../config/env';

type Level = 'info' | 'warn' | 'error' | 'debug';

const isTest = env.NODE_ENV === 'test';

function emit(level: Level, args: unknown[]) {

  if (isTest && level !== 'error') return;

  const ts = new Date().toISOString();
  const prefix = `[${ts}] [${level.toUpperCase()}]`;

  if (level === 'error') {
    console.error(prefix, ...args);
  } else if (level === 'warn') {
    console.warn(prefix, ...args);
  } else {
    console.log(prefix, ...args);
  }
}

export const logger = {
  info:  (...args: unknown[]) => emit('info', args),
  warn:  (...args: unknown[]) => emit('warn', args),
  error: (...args: unknown[]) => emit('error', args),
  debug: (...args: unknown[]) => emit('debug', args),
};
