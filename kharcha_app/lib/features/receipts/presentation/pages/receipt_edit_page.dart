import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kharcha_app/core/widgets/screen_header.dart';
import 'package:kharcha_app/core/error/failures.dart';
import 'package:kharcha_app/core/theme/app_colors.dart';
import 'package:kharcha_app/core/theme/app_text_styles.dart';
import 'package:kharcha_app/core/widgets/app_button.dart';
import 'package:kharcha_app/core/widgets/app_snack_bar.dart';
import 'package:kharcha_app/core/widgets/error_view.dart';
import 'package:kharcha_app/core/widgets/loading_view.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';
import 'package:kharcha_app/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:kharcha_app/features/receipts/presentation/widgets/money.dart';

/// Review screen: fix what the reader got wrong, then confirm.
class ReceiptEditPage extends ConsumerWidget {
  const ReceiptEditPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider(id));
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: CircleBackButton()),
        title: const Text('Review receipt'),
      ),
      body: receipt.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is Failure ? error.message : 'Could not load this receipt.',
          onRetry: () => ref.invalidate(receiptProvider(id)),
        ),
        data: (r) => _EditForm(receipt: r),
      ),
    );
  }
}

/// One editable line item. Controllers live as long as the form.
class _ItemDraft {
  _ItemDraft(ReceiptItem item)
      : name = TextEditingController(text: item.name),
        price = TextEditingController(text: item.price.toStringAsFixed(2)),
        quantity = TextEditingController(text: item.quantity.toString()),
        category = item.category;

  _ItemDraft.blank()
      : name = TextEditingController(),
        price = TextEditingController(),
        quantity = TextEditingController(text: '1'),
        category = null;

  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;
  String? category;

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
  }
}

double? _parseMoney(String text) => double.tryParse(text.trim().replaceAll(',', ''));

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.receipt});

  final Receipt receipt;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _total;
  late final List<_ItemDraft> _items;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    final r = widget.receipt;
    _merchant = TextEditingController(text: r.merchant ?? '');
    _total = TextEditingController(text: r.total?.toStringAsFixed(2) ?? '');
    _items = r.items.map(_ItemDraft.new).toList();
    _date = r.date;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _total.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  /// Items as currently typed; unparsable rows count as zero for the warning.
  double get _typedSum {
    var sum = 0.0;
    for (final i in _items) {
      sum += (_parseMoney(i.price.text) ?? 0) * (int.tryParse(i.quantity.text.trim()) ?? 1);
    }
    return sum;
  }

  bool get _mismatch {
    final total = _parseMoney(_total.text);
    return total != null && _items.isNotEmpty && (_typedSum - total).abs() > 0.01;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.receipt.copyWith(
      merchant: _merchant.text.trim(),
      total: _parseMoney(_total.text),
      date: _date,
      items: [
        for (final i in _items)
          ReceiptItem(
            name: i.name.text.trim(),
            price: _parseMoney(i.price.text) ?? 0,
            quantity: int.tryParse(i.quantity.text.trim()) ?? 1,
            category: i.category,
          ),
      ],
    );

    final ok = await ref.read(updateControllerProvider.notifier).save(updated);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Receipt confirmed.');
      context.pop();
    } else {
      AppSnackBar.error(context, ref.read(updateControllerProvider).error ?? 'Could not save.');
    }
  }

  String? _requiredMoney(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = _parseMoney(v);
    if (n == null || n < 0) return 'Enter a number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(updateControllerProvider).isLoading;
    final currency = widget.receipt.currency;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          TextFormField(
            controller: _merchant,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Store'),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date'),
              child: Text(_date == null ? 'Tap to choose' : formatDate(_date)),
            ),
          ),
          const SizedBox(height: 22),
          Text('Items', style: AppTextStyles.subheading),
          const SizedBox(height: 8),
          for (var i = 0; i < _items.length; i++) _itemCard(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _items.add(_ItemDraft.blank())),
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _total,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Total ($currency)'),
            validator: _requiredMoney,
            onChanged: (_) => setState(() {}),
          ),
          if (_mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Items add up to ${formatMoney(_typedSum, currency)}, which is different from the total. '
                'You can still save if the receipt really says so.',
                style: TextStyle(color: AppColors.amberInk),
              ),
            ),
          const SizedBox(height: 24),
          AppButton(label: 'Confirm receipt', isLoading: saving, onPressed: _save),
        ],
      ),
    );
  }

  Widget _itemCard(int index) {
    final item = _items[index];
    return Container(
      key: ObjectKey(item),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
                child: TextFormField(
                  controller: item.name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _items.removeAt(index).dispose()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: _requiredMoney,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return (n == null || n < 1) ? '1 or more' : null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: receiptCategories.contains(item.category) ? item.category : null,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [for (final c in receiptCategories) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (value) => item.category = value,
          ),
        ],
      ),
    );
  }
}
