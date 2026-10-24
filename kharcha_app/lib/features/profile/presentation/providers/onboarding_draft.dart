import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/features/budgets/di/budgets_di.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';

/// Starting limits offered to a new user. They can change or switch off each one.
const Map<String, double> defaultBudgetLimits = {
  'Groceries': 15000,
  'Dining': 4000,
  'Transport': 6000,
  'Shopping': 5000,
  'Health': 1800,
  'Bills': 8000,
  'Entertainment': 3000,
};

/// Share of the monthly income suggested for each category.
const Map<String, double> _incomeShare = {
  'Groceries': 0.25,
  'Dining': 0.08,
  'Transport': 0.10,
  'Shopping': 0.08,
  'Health': 0.04,
  'Bills': 0.15,
  'Entertainment': 0.05,
};

/// Limits suggested for [income]: each category's share, rounded to the nearest 100.
/// (The rest of the income is left for savings.) Returns {} when income is not positive.
Map<String, double> suggestLimitsFromIncome(double income) {
  if (income <= 0) return {};
  return {
    for (final e in _incomeShare.entries)
      e.key: ((income * e.value) / 100).round() * 100.0,
  };
}

/// The answers collected on the onboarding screens or edited in settings, kept
/// together until the user saves.
class OnboardingDraft {
  const OnboardingDraft({
    this.profile = const UserProfile(),
    this.limits = const {},
    this.original = const {},
    this.tick = 0,
  });

  final UserProfile profile;

  /// category -> monthly limit. A category that is missing has no budget.
  final Map<String, double> limits;

  /// The limits that were already saved when the draft was loaded (settings),
  /// so saving only sends what changed.
  final Map<String, double> original;

  /// Goes up whenever limits are replaced as a whole (for example by a
  /// suggestion), so text fields know to show the new numbers.
  final int tick;

  OnboardingDraft copyWith({
    UserProfile? profile,
    Map<String, double>? limits,
    int? tick,
  }) => OnboardingDraft(
    profile: profile ?? this.profile,
    limits: limits ?? this.limits,
    original: original,
    tick: tick ?? this.tick,
  );
}

class OnboardingDraftController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() {
    // A first-time user starts from the profile the server holds (maybe just
    // their name) and the default limits.
    final profile = ref.read(profileProvider).value ?? const UserProfile();
    return OnboardingDraft(
      profile: profile,
      limits: Map.of(defaultBudgetLimits),
    );
  }

  /// Settings: start from what is saved.
  void load(UserProfile profile, List<Budget> budgets) {
    final saved = {for (final b in budgets) b.category: b.limit};
    state = OnboardingDraft(
      profile: profile,
      limits: Map.of(saved),
      original: saved,
      tick: state.tick + 1,
    );
  }

  void setName(String v) =>
      state = state.copyWith(profile: state.profile.copyWith(displayName: v));

  void setIncome(double? v) => state = state.copyWith(
    profile: v == null
        ? state.profile.copyWith(clearIncome: true)
        : state.profile.copyWith(monthlyIncome: v),
  );

  void setTotalBudget(double? v) => state = state.copyWith(
    profile: v == null
        ? state.profile.copyWith(clearTotalBudget: true)
        : state.profile.copyWith(totalBudget: v),
  );

  void setAlertPercent(int v) =>
      state = state.copyWith(profile: state.profile.copyWith(alertPercent: v));
  void setNotifications(bool v) => state = state.copyWith(
    profile: state.profile.copyWith(notificationsEnabled: v),
  );

  /// null or 0 removes the budget for [category].
  void setLimit(String category, double? v) {
    final next = Map.of(state.limits);
    if (v == null || v <= 0) {
      next.remove(category);
    } else {
      next[category] = v;
    }
    state = state.copyWith(limits: next);
  }

  /// Replaces the limits with the income-based suggestion. Does nothing without an income.
  bool suggestFromIncome() {
    final income = state.profile.monthlyIncome ?? 0;
    final suggested = suggestLimitsFromIncome(income);
    if (suggested.isEmpty) return false;
    state = state.copyWith(limits: suggested, tick: state.tick + 1);
    return true;
  }

  /// Sum of the category limits.
  double get limitsTotal =>
      state.limits.values.fold<double>(0, (a, b) => a + b);

  /// Saves the budgets that changed, then the profile (as onboarded). The
  /// profile goes last, so if something fails the user is not marked as done.
  /// Returns the Failure, or null on success.
  Future<Failure?> save() async {
    final draft = state;
    final setBudget = ref.read(setBudgetUseCaseProvider);
    final removeBudget = ref.read(removeBudgetUseCaseProvider);
    Failure? failure;
    for (final e in draft.limits.entries) {
      if (draft.original[e.key] == e.value) continue;
      final result = await setBudget(
        SetBudgetParams(category: e.key, limit: e.value),
      );
      failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) break;
    }
    if (failure == null) {
      for (final category in draft.original.keys) {
        if (draft.limits.containsKey(category)) continue;
        final result = await removeBudget(
          RemoveBudgetParams(category: category),
        );
        failure = result.fold<Failure?>((f) => f, (_) => null);
        if (failure != null) break;
      }
    }
    // Whatever was saved changes the budget screens, even if a later step failed.
    ref.invalidate(budgetsProvider);
    ref.invalidate(budgetsForMonthProvider);
    if (failure != null) return failure;
    return ref
        .read(profileProvider.notifier)
        .save(draft.profile.copyWith(onboarded: true));
  }
}

final onboardingDraftProvider =
    NotifierProvider.autoDispose<OnboardingDraftController, OnboardingDraft>(
      OnboardingDraftController.new,
    );

/// The categories offered for a budget, in the app's usual order, without "Other".
final List<String> budgetableCategories = receiptCategories
    .where((c) => c != 'Other')
    .toList();
