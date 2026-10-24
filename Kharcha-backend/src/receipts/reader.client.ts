import { env } from '../config/env';
import { Reading } from '../agents/validation.agent';

/**
 * A reader turns a receipt photo into data.
 *   READER=manual  the receipt comes back empty, flagged "needs review", and the user types it in.
 *                  The whole app works that way: this is the "delete the AI" switch.
 *   READER=http    the photo is POSTed to the reader service (../reader), which runs OCR plus the
 *                  trained line and category models.
 * Contract:  POST {READER_URL}/read   body = JPEG bytes   ->   { merchant?, date?, total, items:[{name, qty, price, category}],
 *            confidence, needs_review, readable?, reconciliation? }
 */
export interface RawItem extends Reading {
  /** category label per item, as the reader named it (one of its eight), same order as items */
  itemLabels: Array<string | null>;
  reconciliation?: string;
  confidenceReason?: string;
  tax?: number;
  discount?: number;
  cashPaid?: number | null;
  change?: number | null;
}

export interface ReceiptReader {
  readonly name: 'manual' | 'http';
  read(buffer: Buffer): Promise<RawItem>;
}

const num = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null);

/** Cleans what the reader said so the rest of the backend can trust it. */
export function normalizeReading(raw: unknown): RawItem {
  const d = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  const rawItems = Array.isArray(d.items) ? (d.items as Array<Record<string, unknown>>) : [];
  const good = rawItems.filter((i) => i && typeof i === 'object' && num(i.price) != null && (num(i.price) as number) >= 0);
  const parsed = good.map((i) => {
    const qty = Math.round(num(i.qty ?? i.quantity) ?? 1);
    return {
      name: String(i.name ?? 'Item').trim() || 'Item',
      printedPrice: i.price as number,
      quantity: qty > 0 ? qty : 1,
    };
  });
  // The Python reader reports line totals, while older/custom readers may report
  // unit prices. Choose the interpretation that best explains the printed total.
  // The app contract always stores unit price plus quantity.
  const printedTotal = num(d.total);
  const lineTotalSum = parsed.reduce((sum, i) => sum + i.printedPrice, 0);
  const unitPriceSum = parsed.reduce((sum, i) => sum + i.printedPrice * i.quantity, 0);
  const useUnitPrices =
    printedTotal != null &&
    Math.abs(unitPriceSum - printedTotal) < Math.abs(lineTotalSum - printedTotal);
  const items = parsed.map(({ name, printedPrice, quantity }) => ({
    name,
    price: useUnitPrices ? printedPrice : printedPrice / quantity,
    quantity,
  }));
  const itemLabels = good.map((i) => (typeof i.category === 'string' ? i.category : null));
  const date = typeof d.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(d.date) ? d.date : null;
  const confidence = typeof d.confidence === 'number' && d.confidence >= 0 && d.confidence <= 1 ? d.confidence : undefined;
  return {
    merchant: typeof d.merchant === 'string' && d.merchant.trim() ? d.merchant.trim().slice(0, 120) : null,
    total: printedTotal,
    date,
    currency: 'NPR',
    confidence,
    confidenceReason: typeof d.confidence_reason === 'string' ? d.confidence_reason : undefined,
    readerNeedsReview: d.needs_review === true,
    readable: d.readable === false ? false : true,
    reconciliation: typeof d.reconciliation === 'string' ? d.reconciliation : undefined,
    tax: num(d.tax) ?? undefined,
    discount: num(d.discount) ?? undefined,
    cashPaid: num(d.cash_paid),
    change: num(d.change),
    items,
    itemLabels,
  };
}

export const manualReader: ReceiptReader = {
  name: 'manual',
  async read() {
    return { merchant: null, total: null, date: null, currency: 'NPR', items: [], itemLabels: [], readerNeedsReview: true };
  },
};

export function createHttpReader(opts: {
  url: string;
  token?: string;
  timeoutMs: number;
  fetchImpl?: typeof fetch;
}): ReceiptReader {
  const base = opts.url.replace(/\/$/, '');
  const doFetch = opts.fetchImpl ?? fetch;
  return {
    name: 'http',
    async read(buffer) {
      const headers: Record<string, string> = { 'Content-Type': 'image/jpeg' };
      if (opts.token) headers.Authorization = `Bearer ${opts.token}`;
      const res = await doFetch(`${base}/read`, {
        method: 'POST',
        headers,
        body: new Uint8Array(buffer),
        signal: AbortSignal.timeout(opts.timeoutMs),
      });
      if (!res.ok) throw new Error(`Reader answered ${res.status}`);
      return normalizeReading(await res.json());
    },
  };
}

let reader: ReceiptReader | null = null;
export function getReader(): ReceiptReader {
  if (reader) return reader;
  reader =
    env.READER === 'http'
      ? createHttpReader({ url: env.READER_URL!, token: env.READER_TOKEN, timeoutMs: env.READER_TIMEOUT_MS })
      : manualReader;
  return reader;
}

/** For tests. */
export function setReader(r: ReceiptReader | null): void {
  reader = r;
}
