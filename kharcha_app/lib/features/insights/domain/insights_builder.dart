import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

enum InsightLevel { danger, warning }

/// Where tapping an alert should take the user.
enum InsightTarget { none, budgets, review, receipts }

class InsightAlert {
  const InsightAlert({
    required this.level,
    required this.title,
    required this.body,
    this.target = InsightTarget.none,
  });

  final InsightLevel level;
  final String title;
  final String body;
  final InsightTarget target;
}

class InsightsReport {
  const InsightsReport({required this.alerts, required this.points});

  final List<InsightAlert> alerts;

  /// Plain sentences about the month so far.
  final List<String> points;
}

/// Works out the alerts and the "this month so far" sentences from data the
/// app already has. Plain rules, no AI: the same input always gives the same
/// output, and it works offline.
InsightsReport buildInsights({
  required List<Budget> budgets,
  required List<Receipt> receipts,
  required DashboardSummary? summary,
  required DateTime now,
}) {
  final alerts = <InsightAlert>[];
  final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
  final daysLeftText = daysLeft == 1 ? '1 day' : '$daysLeft days';

  final over = budgets.where((b) => b.level == BudgetLevel.over).toList()
    ..sort((a, b) => b.ratio.compareTo(a.ratio));
  final near = budgets.where((b) => b.level == BudgetLevel.warning).toList()
    ..sort((a, b) => b.ratio.compareTo(a.ratio));

  if (over.length == 1) {
    final b = over.first;
    alerts.add(
      InsightAlert(
        level: InsightLevel.danger,
        title: '${b.category} is over budget',
        body:
            '${formatMoneyShort(b.spent, b.currency)} spent against a ${formatMoneyShort(b.limit, b.currency)} limit.',
        target: InsightTarget.budgets,
      ),
    );
  } else if (over.length > 1) {
    alerts.add(
      InsightAlert(
        level: InsightLevel.danger,
        title: '${over.length} categories are over budget',
        body: '${over.map((b) => b.category).join(', ')}.',
        target: InsightTarget.budgets,
      ),
    );
  }

  final needReview = receipts
      .where((r) => r.status == ReceiptStatus.needsReview)
      .length;
  if (needReview > 0) {
    alerts.add(
      InsightAlert(
        level: InsightLevel.warning,
        title: needReview == 1
            ? '1 receipt needs review'
            : '$needReview receipts need review',
        body: 'They do not count towards your budgets until you approve them.',
        target: InsightTarget.review,
      ),
    );
  }

  for (final group in _duplicateGroups(receipts).take(2)) {
    final first = group.first;
    alerts.add(
      InsightAlert(
        level: InsightLevel.warning,
        title: 'Possible duplicate receipt',
        body:
            '${group.length == 2 ? 'Two' : '${group.length}'} ${first.title} receipts for '
            '${formatMoneyShort(first.total, first.currency)} on ${formatDate(first.date)}. Check them in My receipts.',
        target: InsightTarget.receipts,
      ),
    );
  }

  if (near.isNotEmpty) {
    final names = near.map((b) => b.category).toList();
    final percents = near.map((b) => '${(b.ratio * 100).round()}%').toList();
    alerts.add(
      InsightAlert(
        level: InsightLevel.warning,
        title: names.length == 1
            ? '${names.first} is near its limit'
            : '${_joinNames(names)} are near their limits',
        body: 'At ${_joinNames(percents)} with $daysLeftText to go.',
        target: InsightTarget.budgets,
      ),
    );
  }

  return InsightsReport(
    alerts: alerts,
    points: _points(budgets, over, summary, now),
  );
}

List<String> _points(
  List<Budget> budgets,
  List<Budget> over,
  DashboardSummary? summary,
  DateTime now,
) {
  if (summary == null || summary.isEmpty) return const [];
  final points = <String>[];

  final top = summary.topCategories;
  if (top.isNotEmpty && summary.total > 0) {
    final share = (top.first.amount / summary.total * 100).round();
    points.add(
      '${top.first.category} is your biggest category, about $share% of everything spent.',
    );
  }

  final change = summary.changePercent;
  if (change != null && change.abs() >= 1) {
    points.add(
      'Spending is ${change > 0 ? 'up' : 'down'} ${change.abs().round()}% compared with last month.',
    );
  }

  if (over.length == 1) {
    points.add(
      '${over.first.category} is the only category already over its budget.',
    );
  } else if (over.length > 1) {
    points.add('${over.length} categories are already over their budgets.');
  } else if (budgets.isNotEmpty) {
    points.add('No category is over its budget yet.');
  }

  if (now.day > 0 && summary.total > 0) {
    points.add(
      'You are spending about ${formatMoneyShort(summary.total / now.day, summary.currency)} a day so far.',
    );
  }
  return points;
}

/// Receipts with the same merchant, total and day, which is how a receipt
/// scanned twice looks. Receipts that are still being read are ignored.
List<List<Receipt>> _duplicateGroups(List<Receipt> receipts) {
  final groups = <String, List<Receipt>>{};
  for (final r in receipts) {
    if (r.status == ReceiptStatus.processing ||
        r.status == ReceiptStatus.failed) {
      continue;
    }
    if (r.merchant == null || r.total == null || r.date == null) continue;
    final key =
        '${r.merchant!.trim().toLowerCase()}|${r.total!.toStringAsFixed(2)}|'
        '${r.date!.year}-${r.date!.month}-${r.date!.day}';
    groups.putIfAbsent(key, () => []).add(r);
  }
  return groups.values.where((g) => g.length > 1).toList();
}

String _joinNames(List<String> names) {
  if (names.length <= 1) return names.join();
  if (names.length == 2) return '${names[0]} and ${names[1]}';
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}
