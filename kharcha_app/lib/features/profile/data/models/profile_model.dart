import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';

double? _toDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// JSON <-> UserProfile. Tolerant: a missing field falls back to its default.
class ProfileModel {
  static Map<String, dynamic> toJson(UserProfile p) => {
    if (p.displayName.trim().isNotEmpty) 'name': p.displayName.trim(),
    'currency': 'NPR', // rupees only
    'monthlyIncome': p.monthlyIncome,
    'totalBudget': p.totalBudget,
    'alertPercent': p.alertPercent,
    'notificationsEnabled': p.notificationsEnabled,
    'onboardingCompleted': p.onboarded,
  };

  /// Accepts the backend's { "user": {...} } or the bare user object.
  static UserProfile fromJson(Map<String, dynamic> body) {
    final inner = body['user'];
    final json = inner is Map<String, dynamic> ? inner : body;
    final percent = (json['alertPercent'] as num?)?.toInt() ?? 80;
    return UserProfile(
      displayName:
          (json['name'] as String?) ?? (json['displayName'] as String?) ?? '',
      currency: 'NPR', // rupees only: whatever the server stored
      monthlyIncome: _toDouble(json['monthlyIncome']),
      totalBudget: _toDouble(json['totalBudget']),
      alertPercent: percent.clamp(50, 100),
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
      onboarded:
          (json['onboardingCompleted'] as bool?) ??
          (json['onboarded'] as bool?) ??
          false,
    );
  }
}
