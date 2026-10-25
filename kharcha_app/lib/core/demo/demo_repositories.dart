import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:kharcha_app/core/demo/demo_store.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';
import 'package:kharcha_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/domain/repositories/receipts_repository.dart';

/// One store for the whole app run, shared by the three demo repositories.
final demoStoreProvider = Provider<DemoStore>((ref) => DemoStore());

/// A short pause so loading states are visible, like a real network call.
Future<void> _latency() =>
    Future<void>.delayed(const Duration(milliseconds: 350));

class DemoReceiptRepository implements ReceiptRepository {
  DemoReceiptRepository(this._store);

  final DemoStore _store;

  @override
  Future<Either<Failure, Receipt>> upload(
    Uint8List jpeg, {
    String? idempotencyKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return Right(_store.addScanned());
  }

  @override
  Future<Either<Failure, List<Receipt>>> list() async {
    await _latency();
    return Right(_store.receipts);
  }

  @override
  Future<Either<Failure, Receipt>> get(String id) async {
    await _latency();
    final found = _store.byId(id);
    if (found == null) {
      return const Left(ServerFailure('Receipt not found.', statusCode: 404));
    }
    return Right(found);
  }

  @override
  Future<Either<Failure, Receipt>> update(Receipt receipt) async {
    await _latency();
    return Right(_store.replace(receipt));
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    await _latency();
    _store.removeReceipt(id);
    return const Right(unit);
  }
}

class DemoBudgetRepository implements BudgetRepository {
  DemoBudgetRepository(this._store);

  final DemoStore _store;

  @override
  Future<Either<Failure, List<Budget>>> list({String? month}) async {
    await _latency();
    return Right(_store.budgets(month: month));
  }

  @override
  Future<Either<Failure, Budget>> setLimit({
    required String category,
    required double limit,
    String? month,
  }) async {
    await _latency();
    return Right(_store.setLimit(category, limit, month: month));
  }

  @override
  Future<Either<Failure, Unit>> remove(String category, {String? month}) async {
    await _latency();
    _store.removeBudget(category, month: month);
    return const Right(unit);
  }
}

class DemoProfileRepository implements ProfileRepository {
  DemoProfileRepository(this._store);

  final DemoStore _store;

  @override
  Future<Either<Failure, UserProfile>> get() async {
    await _latency();
    return Right(_store.profile);
  }

  @override
  Future<Either<Failure, UserProfile>> save(UserProfile profile) async {
    await _latency();
    return Right(_store.saveProfile(profile));
  }
}

class DemoDashboardRepository implements DashboardRepository {
  DemoDashboardRepository(this._store);

  final DemoStore _store;

  @override
  Future<Either<Failure, DashboardSummary>> summary({String? month}) async {
    await _latency();
    return Right(_store.summary(month: month));
  }

  @override
  Future<Either<Failure, List<MonthTotal>>> trend({int months = 6}) async {
    await _latency();
    return Right(_store.trend(months: months));
  }
}
