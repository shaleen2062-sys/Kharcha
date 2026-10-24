import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';

/// Bottom sheet to add a budget, or change / remove an existing one.
Future<void> showBudgetSheet(
  BuildContext context, {
  Budget? existing,
  required List<String> usedCategories,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BudgetSheet(existing: existing, usedCategories: usedCategories),
  );
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet({required this.existing, required this.usedCategories});

  final Budget? existing;
  final List<String> usedCategories;

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  late final TextEditingController _limit;
  String? _category;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category;
    _limit = TextEditingController(
      text: widget.existing == null ? '' : widget.existing!.limit.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limit = double.tryParse(_limit.text.trim().replaceAll(',', ''));
    if (_category == null) {
      setState(() => _error = 'Choose a category.');
      return;
    }
    if (limit == null || limit <= 0) {
      setState(() => _error = 'Enter a limit above zero.');
      return;
    }
    final failure = await ref.read(budgetActionsProvider.notifier).save(_category!, limit);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, failure);
    }
  }

  Future<void> _remove() async {
    final failure = await ref.read(budgetActionsProvider.notifier).remove(_category!);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(budgetActionsProvider).isLoading;
    final available = receiptCategories
        .where((c) => !widget.usedCategories.contains(c) || c == widget.existing?.category)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_editing ? 'Edit budget' : 'New budget', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [for (final c in available) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: _editing ? null : (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limit,
            autofocus: !_editing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monthly limit',
              prefixText: '${widget.existing?.currency ?? 'NPR'} ',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Save', isLoading: busy, onPressed: _save),
          if (_editing) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'Remove budget',
              variant: AppButtonVariant.outlined,
              onPressed: busy ? null : _remove,
            ),
          ],
        ],
      ),
    );
  }
}
