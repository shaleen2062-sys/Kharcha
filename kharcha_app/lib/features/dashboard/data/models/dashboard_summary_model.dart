import 'package:kharcha_app/core/network/category_names.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';

double _num(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class DashboardSummaryModel {
  static Map<String, dynamic> toJson(DashboardSummary s) => {
        'month': s.month,
        'total': s.total,
        'previousTotal': s.previousTotal,
        'currency': s.currency,
        'receiptCount': s.receiptCount,
        'byCategory': [for (final c in s.byCategory) {'category': c.category, 'amount': c.amount}],
        'daily': [for (final d in s.daily) {'day': d.day, 'amount': d.amount}],
        'previousByCategory': [for (final c in s.previousByCategory) {'category': c.category, 'amount': c.amount}],
      };

  static DashboardSummary fromJson(Map<String, dynamic> json) {
    final cats = json['byCategory'];
    final daily = json['daily'];
    final prevCats = json['previousByCategory'];
    return DashboardSummary(
      month: (json['month'] as String?) ?? '',
      total: _num(json['total']),
      previousTotal: _num(json['previousTotal']),
      currency: (json['currency'] as String?) ?? 'NPR',
      receiptCount: (json['receiptCount'] as num?)?.toInt() ?? 0,
      byCategory: cats is List
          ? cats
              .whereType<Map<String, dynamic>>()
              .map((c) => CategorySpend(category: CategoryNames.fromApi(c['category'] as String?) ?? 'Other', amount: _num(c['amount'])))
              .toList()
          : const [],
      daily: daily is List
          ? daily
              .whereType<Map<String, dynamic>>()
              .map((d) => DailySpend(day: (d['day'] as num?)?.toInt() ?? 0, amount: _num(d['amount'])))
              .toList()
          : const [],
      previousByCategory: prevCats is List
          ? prevCats
              .whereType<Map<String, dynamic>>()
              .map((c) => CategorySpend(category: CategoryNames.fromApi(c['category'] as String?) ?? 'Other', amount: _num(c['amount'])))
              .toList()
          : const [],
    );
  }
}
