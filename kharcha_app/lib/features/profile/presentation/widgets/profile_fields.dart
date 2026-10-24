import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha_app/features/profile/presentation/providers/onboarding_draft.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// "12,500" -> 12500, "" -> null, "abc" -> null.
double? parseAmount(String text) {
  final cleaned = text.replaceAll(',', '').replaceAll(' ', '').trim();
  if (cleaned.isEmpty) return null;
  final v = double.tryParse(cleaned);
  return (v == null || v < 0) ? null : v;
}

/// A number field that edits a nullable amount. It shows [value] and reports
/// every change; when [value] is changed from outside (for example by a
/// suggestion) the text follows.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.prefix,
    this.helper,
  });

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? prefix;
  final String? helper;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );

  static String _format(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }

  @override
  void didUpdateWidget(AmountField old) {
    super.didUpdateWidget(old);
    // Only rewrite the text when it no longer matches, so typing "12." is left alone.
    if (parseAmount(_controller.text) != widget.value)
      _controller.text = _format(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (t) => widget.onChanged(parseAmount(t)),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: widget.prefix,
        helperText: widget.helper,
      ),
    );
  }
}

/// The user's name.
class ProfileFields extends ConsumerStatefulWidget {
  const ProfileFields({super.key});

  @override
  ConsumerState<ProfileFields> createState() => _ProfileFieldsState();
}

class _ProfileFieldsState extends ConsumerState<ProfileFields> {
  late final TextEditingController _name = TextEditingController(
    text: ref.read(onboardingDraftProvider).profile.displayName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.read(onboardingDraftProvider.notifier);
    return TextField(
      controller: _name,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onChanged: draft.setName,
      decoration: const InputDecoration(labelText: 'Your name'),
    );
  }
}

/// Monthly income and an optional overall spending cap.
class IncomeFields extends ConsumerWidget {
  const IncomeFields({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingDraftProvider.select((d) => d.profile));
    final draft = ref.read(onboardingDraftProvider.notifier);
    return Column(
      children: [
        AmountField(
          label: 'Monthly income (optional)',
          prefix: 'Rs ',
          value: profile.monthlyIncome,
          onChanged: draft.setIncome,
        ),
        const SizedBox(height: 16),
        AmountField(
          label: 'Overall monthly spending limit (optional)',
          prefix: 'Rs ',
          value: profile.totalBudget,
          helper:
              'A cap for everything together, on top of the category budgets.',
          onChanged: draft.setTotalBudget,
        ),
      ],
    );
  }
}

/// One switch and one amount per category.
class BudgetFields extends ConsumerWidget {
  const BudgetFields({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingDraftProvider);
    final draft = ref.read(onboardingDraftProvider.notifier);
    final total = state.limits.values.fold<double>(0, (a, b) => a + b);
    final income = state.profile.monthlyIncome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((income ?? 0) > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: draft.suggestFromIncome,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: const Text('Suggest from my income'),
            ),
          ),
        for (final category in budgetableCategories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: state.limits.containsKey(category),
                        onChanged: (on) => draft.setLimit(
                          category,
                          on ? (defaultBudgetLimits[category] ?? 2000) : null,
                        ),
                      ),
                    ],
                  ),
                  if (state.limits.containsKey(category))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AmountField(
                        label: 'Monthly limit',
                        prefix: 'Rs ',
                        value: state.limits[category],
                        onChanged: (v) => draft.setLimit(category, v),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          total <= 0
              ? 'No category budgets yet.'
              : 'Category budgets add up to ${formatMoneyShort(total)} a month.',
          style: AppTextStyles.caption,
        ),
        if ((income ?? 0) > 0 && total > income!)
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'That is more than your monthly income.',
              style: TextStyle(color: AppColors.amberInk),
            ),
          ),
      ],
    );
  }
}

/// When to warn, and whether to notify.
class AlertFields extends ConsumerWidget {
  const AlertFields({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingDraftProvider.select((d) => d.profile));
    final draft = ref.read(onboardingDraftProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warn me at ${profile.alertPercent}% of a budget',
          style: AppTextStyles.subheading,
        ),
        Slider(
          value: profile.alertPercent.toDouble(),
          min: 50,
          max: 100,
          divisions: 10,
          label: '${profile.alertPercent}%',
          onChanged: (v) => draft.setAlertPercent(v.round()),
        ),
        Text(
          'You also get an alert when a budget is used up.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notifications'),
          subtitle: const Text('Tell me when a budget is near its limit.'),
          value: profile.notificationsEnabled,
          onChanged: draft.setNotifications,
        ),
      ],
    );
  }
}
