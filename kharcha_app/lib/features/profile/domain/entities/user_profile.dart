/// What the user told the app about themselves during onboarding.
/// Pure Dart: no JSON here.
class UserProfile {
  const UserProfile({
    this.displayName = '',
    this.currency = 'NPR',
    this.monthlyIncome,
    this.totalBudget,
    this.alertPercent = 80,
    this.notificationsEnabled = true,
    this.onboarded = false,
  });

  final String displayName;
  final String currency;

  /// What the user earns per month, if they chose to say.
  final double? monthlyIncome;

  /// An overall monthly spending cap, if they set one.
  final double? totalBudget;

  /// A budget is flagged "near its limit" from this percent (50 to 100).
  final int alertPercent;
  final bool notificationsEnabled;

  /// false until the user has finished the onboarding screens.
  final bool onboarded;

  UserProfile copyWith({
    String? displayName,
    String? currency,
    double? monthlyIncome,
    double? totalBudget,
    int? alertPercent,
    bool? notificationsEnabled,
    bool? onboarded,
    bool clearIncome = false,
    bool clearTotalBudget = false,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      monthlyIncome: clearIncome ? null : (monthlyIncome ?? this.monthlyIncome),
      totalBudget: clearTotalBudget ? null : (totalBudget ?? this.totalBudget),
      alertPercent: alertPercent ?? this.alertPercent,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.displayName == displayName &&
      other.currency == currency &&
      other.monthlyIncome == monthlyIncome &&
      other.totalBudget == totalBudget &&
      other.alertPercent == alertPercent &&
      other.notificationsEnabled == notificationsEnabled &&
      other.onboarded == onboarded;

  @override
  int get hashCode => Object.hash(
    displayName,
    currency,
    monthlyIncome,
    totalBudget,
    alertPercent,
    notificationsEnabled,
    onboarded,
  );
}
