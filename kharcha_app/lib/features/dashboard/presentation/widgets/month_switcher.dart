import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/features/dashboard/presentation/providers/dashboard_providers.dart';

/// "‹  October 2026  ›": step through months, or tap the name to pick one.
/// The right arrow is switched off on the current month.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final isCurrent = month == monthKey(DateTime.now());

    Widget arrow(IconData icon, String label, VoidCallback? onTap) => Semantics(
          button: true,
          label: label,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 44,
              child: Icon(icon, color: onTap == null ? AppColors.line : AppColors.ink),
            ),
          ),
        );

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left, 'Previous month', () => notifier.shift(-1)),
          InkWell(
            onTap: () => showMonthPicker(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(monthLabelOfKey(month), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          arrow(Icons.chevron_right, 'Next month', isCurrent ? null : () => notifier.shift(1)),
        ],
      ),
    );
  }
}

/// Bottom sheet with a year and twelve months. Months after the current one
/// are greyed out.
Future<void> showMonthPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _MonthPickerSheet(
      selected: ref.read(selectedMonthProvider),
      onPick: (key) {
        ref.read(selectedMonthProvider.notifier).set(key);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.selected, required this.onPick});

  final String selected;
  final ValueChanged<String> onPick;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = monthStart(widget.selected).year;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentKey = monthKey(now);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous year',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _year > 2000 ? () => setState(() => _year--) : null,
                ),
                SizedBox(width: 80, child: Center(child: Text('$_year', style: AppTextStyles.subheading))),
                IconButton(
                  tooltip: 'Next year',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _year < now.year ? () => setState(() => _year++) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.9,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: shortMonthName(m),
                    selected: widget.selected == monthKey(DateTime(_year, m, 1)),
                    enabled: monthKey(DateTime(_year, m, 1)).compareTo(currentKey) <= 0,
                    onTap: () => widget.onPick(monthKey(DateTime(_year, m, 1))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.label, required this.selected, required this.enabled, required this.onTap});

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : (enabled ? AppColors.ink : AppColors.line),
            ),
          ),
        ),
      ),
    );
  }
}
