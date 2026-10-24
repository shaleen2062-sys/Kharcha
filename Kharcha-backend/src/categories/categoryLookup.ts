import { Types } from 'mongoose';
import { listCategories } from './categories.service';
import { CategoryNames } from '../dashboard/stats';

export interface CategoryIndex extends CategoryNames {
  /** lower-case name -> id */
  idByName: Map<string, string>;
  all: Array<{ id: string; name: string }>;
}

/** The user's categories in the shapes the services need. */
export async function categoryIndex(userId: Types.ObjectId): Promise<CategoryIndex> {
  const docs = await listCategories(userId);
  const names = new Map<string, string>();
  const idByName = new Map<string, string>();
  let fallbackId = '';
  for (const c of docs) {
    const id = String(c._id);
    names.set(id, c.name);
    idByName.set(c.name.toLowerCase(), id);
    if (c.isFallback) fallbackId = id;
  }
  return { names, idByName, fallbackId, all: [...names].map(([id, name]) => ({ id, name })) };
}
