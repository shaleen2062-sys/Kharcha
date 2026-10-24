/**
 * Demo data: one dev user with confirmed receipts spread over the last three months and a few budgets,
 * so the dashboard, budgets and alerts screens have something to show.
 *   npm run seed            (needs MONGODB_URI; creates the user "dev:demo")
 */
import mongoose from 'mongoose';
import { connectDB, disconnectDB } from '../src/config/db';
import { getOrCreateUser } from '../src/users/users.service';
import { categoryIndex } from '../src/categories/categoryLookup';
import { Receipt } from '../src/receipts/receipt.model';
import { Budget } from '../src/budgets/budget.model';
import { dateInTz, monthOf, prevMonth } from '../src/utils/dates';
import { itemsSum } from '../src/utils/money';
import { env } from '../src/config/env';

const STORES: Array<{ merchant: string; items: Array<[string, number, number, string]> }> = [
  { merchant: 'Bhat-Bhateni Supermarket', items: [['Rice 5kg', 850, 1, 'Groceries'], ['Milk 1L', 110, 2, 'Groceries'], ['Eggs (tray)', 420, 1, 'Groceries'], ['Shampoo', 380, 1, 'Personal Care']] },
  { merchant: 'Himalayan Java', items: [['Cappuccino', 280, 2, 'Food & Dining'], ['Brownie', 220, 1, 'Food & Dining']] },
  { merchant: 'Pathao', items: [['Ride to Patan', 310, 1, 'Transport']] },
  { merchant: 'Om Pharmacy', items: [['Paracetamol strip', 40, 2, 'Healthcare'], ['Vitamin C', 260, 1, 'Healthcare']] },
  { merchant: 'NTC Recharge', items: [['Data pack', 599, 1, 'Utilities']] },
  { merchant: 'QFX Cinemas', items: [['Movie ticket', 450, 2, 'Entertainment'], ['Popcorn', 300, 1, 'Entertainment']] },
];

async function main() {
  await connectDB();
  const user = await getOrCreateUser('demo', 'demo@kharcha.test', 'Demo User');
  const cats = await categoryIndex(user._id);
  await Receipt.deleteMany({ userId: user._id });
  await Budget.deleteMany({ userId: user._id });

  const today = dateInTz(env.APP_TZ);
  const month0 = monthOf(today);
  const months = [prevMonth(prevMonth(month0)), prevMonth(month0), month0];
  let n = 0;
  for (const month of months) {
    const lastDay = month === month0 ? Number(today.slice(8, 10)) : 28;
    for (let d = 1; d <= lastDay; d += 3) {
      const store = STORES[(d + n) % STORES.length];
      const items = store.items.map(([name, price, quantity, cat]) => ({
        name, price, quantity, categoryId: cats.idByName.get(cat.toLowerCase()) ?? null,
      }));
      await Receipt.create({
        userId: user._id, status: 'confirmed', merchant: store.merchant, currency: 'NPR',
        total: itemsSum(items), date: `${month}-${String(d).padStart(2, '0')}`, items, source: 'manual',
      });
      n++;
    }
  }
  for (const [name, limit] of [['Groceries', 6000], ['Food & Dining', 3000], ['Transport', 2000]] as const) {
    await Budget.create({ userId: user._id, categoryId: cats.idByName.get(name.toLowerCase()), effectiveFrom: months[0], limit });
  }
  console.log(`Seeded ${n} receipts and 3 budgets for user "demo". Use header: Authorization: Bearer dev:demo`);
  await disconnectDB();
  await mongoose.disconnect();
}

main().catch((e) => { console.error(e); process.exit(1); });
