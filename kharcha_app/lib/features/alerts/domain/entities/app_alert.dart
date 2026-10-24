enum AlertKind {
  budgetWarning,
  budgetExceeded,
  possibleDuplicate,
  needsReview,
  other;

  static AlertKind parse(String? raw) => switch (raw) {
        'budget_warning' => AlertKind.budgetWarning,
        'budget_exceeded' => AlertKind.budgetExceeded,
        'possible_duplicate' => AlertKind.possibleDuplicate,
        'needs_review' => AlertKind.needsReview,
        _ => AlertKind.other,
      };
}

/// One in-app notification raised by the backend (budget at 80% / over 100%, receipt needs a look).
class AppAlert {
  const AppAlert({
    required this.id,
    required this.kind,
    required this.message,
    this.receiptId,
    this.createdAt,
    this.read = false,
  });

  final String id;
  final AlertKind kind;
  final String message;
  final String? receiptId;
  final DateTime? createdAt;
  final bool read;

  static AppAlert fromJson(Map<String, dynamic> j) => AppAlert(
        id: (j['id'] ?? j['_id']).toString(),
        kind: AlertKind.parse(j['type'] as String?),
        message: (j['message'] as String?) ?? '',
        receiptId: j['receiptId'] as String?,
        createdAt: j['createdAt'] is String ? DateTime.tryParse(j['createdAt'] as String)?.toLocal() : null,
        read: j['readAt'] != null,
      );
}

class AlertsState {
  const AlertsState(this.alerts, this.unreadCount);
  final List<AppAlert> alerts;
  final int unreadCount;
  static const empty = AlertsState([], 0);
}
