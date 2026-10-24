import 'package:kharcha_app/core/network/category_names.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';

double _num(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class BudgetModel {
  static Map<String, dynamic> toJson(Budget b) =>
      {'category': b.category, 'limit': b.limit, 'spent': b.spent, 'currency': b.currency};

  static Budget fromJson(Map<String, dynamic> json) {
    return Budget(
      category: CategoryNames.fromApi(json['category'] as String?) ?? 'Other',
      limit: _num(json['limit']),
      spent: _num(json['spent']),
      currency: (json['currency'] as String?) ?? 'NPR',
    );
  }
}
