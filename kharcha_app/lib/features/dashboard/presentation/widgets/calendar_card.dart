import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/router/route_names.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/receipt_image.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/status_chip.dart';

const List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Receipts dated on [day] of the month [key], newest first as the list gives them.
List<Receipt> receiptsOnDay(List<Receipt> all, String key, int day) {
  return all.where((r) {
    final d = r.date;
    return d != null && monthKey(d) == key && d.day == day;
  }).toList();
}

/// A month as a calendar: each day is tinted by how much was spent, tap a day
/// to see its receipts underneath.
class CalendarCard extends ConsumerStatefulWidget {
  const CalendarCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  ConsumerState<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends ConsumerState<CalendarCard> {
  int? _selected;

  @override
  void didUpdateWidget(CalendarCard old) {
    super.didUpdateWidget(old);
    if (old.summary.month != widget.summary.month) _selected = null; // a new month: forget the old day
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final key = s.month;
    final days = daysInMonth(key);
    final blanks = calendarLeadingBlanks(key);
    final now = DateTime.now();
    final isCurrent = key == monthKey(now);
    final peak = s.daily.fold<double>(0, (p, d) => d.amount > p ? d.amount : p);
    final monthDate = monthStart(key);

    Widget cell(int day) {
      final amount = s.spentOnDay(day);
      final future = isCurrent && day > now.day;
      final isToday = isCurrent && day == now.day;
      final selected = _selected == day;
      final t = peak <= 0 ? 0.0 : (amount / peak).clamp(0.0, 1.0);
      final fill = selected
          ? AppColors.ink
          : amount > 0
              ? Color.lerp(AppColors.primarySoft, AppColors.primary, t)!
              : Colors.transparent;
      final textColor = selected || t > 0.6 ? Colors.white : (future ? AppColors.line : AppColors.ink);
      return Semantics(
        button: !future,
        label: '$day ${monthLabelOfKey(key)}${amount > 0 ? ', spent ${formatMoneyShort(amount)}' : ''}',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: future ? null : () => setState(() => _selected = selected ? null : day),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
              border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(fontSize: 14, fontWeight: amount > 0 ? FontWeight.w700 : FontWeight.w500, color: textColor),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Text('Calendar', style: AppTextStyles.subheading)),
                Text('Darker = spent more', style: AppTextStyles.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(child: Text(w.substring(0, 1), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600))),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
              for (var d = 1; d <= days; d++) cell(d),
            ],
          ),
          if (_selected != null) ...[
            const Divider(height: 20),
            _DayList(
              title:
                  '${_weekdays[DateTime(monthDate.year, monthDate.month, _selected!).weekday % 7]} $_selected ${shortMonthName(monthDate.month)}',
              amount: s.spentOnDay(_selected!),
              receipts: receiptsOnDay(ref.watch(receiptsProvider).value ?? const <Receipt>[], key, _selected!),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.title, required this.amount, required this.receipts});

  final String title;
  final double amount;
  final List<Receipt> receipts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(amount > 0 ? formatMoneyShort(amount) : 'Nothing spent', style: AppTextStyles.caption),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (receipts.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(4, 6, 4, 4),
            child: Text('No receipts on this day.', style: TextStyle(color: AppColors.muted)),
          )
        else
          for (final r in receipts)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.push(RoutePaths.receiptDetailFor(r.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 52,
                      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: ReceiptImage(receipt: r)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatMoneyShort(r.total, r.currency), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        StatusChip(r.status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
