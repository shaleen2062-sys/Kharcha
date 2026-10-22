import { User, UserDoc } from './user.model';
import { seedDefaultCategories } from '../categories/categories.service';
import { logger } from '../utils/logger';

export async function getOrCreateUser(
  uid: string,
  email?: string,
  name?: string,
): Promise<UserDoc> {
  const existing = await User.exists({ uid });
  const isNew = !existing;

  const user = await User.findOneAndUpdate(
    { uid },
    {
      $set: {
        ...(email ? { email } : {}),
        ...(name ? { name } : {}),
        lastLoginAt: new Date(),
      },
      $setOnInsert: { uid },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  if (isNew) {
    try {
      await seedDefaultCategories(user._id);
    } catch (err) {
      logger.error({ err, uid }, 'Failed to seed default categories');
    }
  }

  return user;
}

export const getUser = (id: string) => User.findById(id);
export const getUserByFirebaseUid = (uid: string) => User.findOne({ uid });

export type UserPatch = Partial<
  Pick<
    UserDoc,
    | 'name'
    | 'photoUrl'
    | 'currency'
    | 'aiEnabled'
    | 'onboardingCompleted'
  >
>;

export const updateUser = (id: string, patch: UserPatch) =>
  User.findByIdAndUpdate(id, { $set: patch }, { new: true, runValidators: true }).lean();

export const softDeleteUser = (id: string) =>
  User.findByIdAndUpdate(id, { $set: { deletedAt: new Date() } }, { new: true }).lean();

export const hardDeleteUser = (id: string) => User.deleteOne({ _id: id });