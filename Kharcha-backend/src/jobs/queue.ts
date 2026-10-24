import { logger } from '../utils/logger';

/**
 * Background jobs. This is a small in-process queue: the upload request answers at once and the
 * photo is read right after. It does NOT survive a server restart; receipts stuck in "processing"
 * are picked up again by requeueStuck() in processReceipt.ts when the server starts.
 * To move to BullMQ + Redis, keep the `enqueue` signature and swap this file.
 */
export interface JobQueue {
  enqueue(name: string, job: () => Promise<void>): void;
  /** Resolves when everything queued so far has finished (used by tests). */
  idle(): Promise<void>;
}

class InlineQueue implements JobQueue {
  private running = 0;
  private readonly waiting: Array<() => Promise<void>> = [];
  private idleWaiters: Array<() => void> = [];

  constructor(private readonly concurrency = 2) {}

  enqueue(name: string, job: () => Promise<void>): void {
    this.waiting.push(async () => {
      try {
        await job();
      } catch (err) {
        logger.error({ err, job: name }, 'Background job failed');
      }
    });
    this.pump();
  }

  private pump(): void {
    while (this.running < this.concurrency && this.waiting.length > 0) {
      const next = this.waiting.shift()!;
      this.running++;
      void next().finally(() => {
        this.running--;
        this.pump();
        if (this.running === 0 && this.waiting.length === 0) {
          const w = this.idleWaiters;
          this.idleWaiters = [];
          w.forEach((f) => f());
        }
      });
    }
  }

  idle(): Promise<void> {
    if (this.running === 0 && this.waiting.length === 0) return Promise.resolve();
    return new Promise((resolve) => this.idleWaiters.push(resolve));
  }
}

export const queue: JobQueue = new InlineQueue();
