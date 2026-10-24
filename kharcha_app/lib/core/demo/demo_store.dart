import 'package:kharcha_app/core/config/env.dart';
import 'package:kharcha_app/core/utils/date_utils.dart';
import 'package:kharcha_app/features/budgets/domain/entities/budget.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:kharcha_app/features/dashboard/domain/entities/month_total.dart';
import 'package:kharcha_app/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha_app/features/receipts/domain/entities/receipt.dart';

/// A budget limit that starts in [from] ("YYYY-MM"). A null [limit] means the
/// budget was removed from that month on. This is how past months keep the
/// limits they had when the user changes a budget later.
class _LimitChange {
  const _LimitChange(this.from, this.limit);
  final String from;
  final double? limit;
}

/// Fake data for running the app with no backend (see Env.useDemoData).
///
/// Everything is worked out from the receipts, the same way the real backend
/// does it: only confirmed receipts count, so approving a receipt in the app
/// moves the dashboard and the budgets. Besides this month there are three
/// earlier months, so the calendar and the month-vs-month card have something
/// to show.
class DemoStore {
  DemoStore({DateTime? now})
      : _now = now ?? DateTime.now(),
        _limits = {
          for (final e in const {
            'Groceries': 15000.0,
            'Dining': 4000.0,
            'Transport': 6000.0,
            'Shopping': 5000.0,
            'Health': 1800.0,
            'Bills': 8000.0,
          }.entries)
            e.key: [_LimitChange('2000-01', e.value)],
        } {
    _receipts = [..._seed(_now), ..._history(_now)];
  }

  final DateTime _now;
  final Map<String, List<_LimitChange>> _limits;
  late List<Receipt> _receipts;
  int _nextId = 100;

  String get _currentKey => monthKey(_now);

  /// Newest first, like the backend.
  List<Receipt> get receipts => List.unmodifiable(_receipts);

  Receipt? byId(String id) {
    for (final r in _receipts) {
      if (r.id == id) return r;
    }
    return null;
  }

  Receipt replace(Receipt receipt) {
    final saved = receipt.copyWith(status: ReceiptStatus.confirmed);
    _receipts = [for (final r in _receipts) r.id == saved.id ? saved : r];
    return saved;
  }

  /// A freshly scanned receipt: the "reader" found something that needs a look.
  Receipt addScanned() {
    final sample = _scanSamples[_nextId % _scanSamples.length];
    final id = 'demo-${_nextId++}';
    final receipt = Receipt(
      id: id,
      status: ReceiptStatus.needsReview,
      merchant: sample.merchant,
      total: sample.total,
      date: _day(0),
      imageUrl: 'demo://$id',
      items: sample.items,
    );
    _receipts = [receipt, ..._receipts];
    return receipt;
  }

  // Profile ------------------------------------------------------------

  UserProfile _profile = const UserProfile(displayName: 'Demo user', onboarded: Env.demoOnboarded);

  UserProfile get profile => _profile;

  UserProfile saveProfile(UserProfile profile) => _profile = profile;

  // Budgets ------------------------------------------------------------

  /// The limit in force for [category] in [month], or null when it has none.
  double? limitFor(String category, String month) {
    double? found;
    String? foundFrom;
    for (final c in _limits[category] ?? const <_LimitChange>[]) {
      if (c.from.compareTo(month) <= 0 && (foundFrom == null || c.from.compareTo(foundFrom) >= 0)) {
        found = c.limit;
        foundFrom = c.from;
      }
    }
    return found;
  }

  /// Budgets in force in [month] (null = this month) with that month's spending.
  List<Budget> budgets({String? month}) {
    final key = month ?? _currentKey;
    final spent = _spentByCategory(key);
    final list = <Budget>[];
    for (final category in _limits.keys) {
      final limit = limitFor(category, key);
      if (limit != null) list.add(Budget(category: category, limit: limit, spent: spent[category] ?? 0));
    }
    // Keep the same order as the category list.
    list.sort((a, b) => receiptCategories.indexOf(a.category).compareTo(receiptCategories.indexOf(b.category)));
    return list;
  }

  /// Sets the limit from [month] on (null = this month). Earlier months keep theirs.
  Budget setLimit(String category, double limit, {String? month}) {
    final from = month ?? _currentKey;
    _addChange(category, _LimitChange(from, limit));
    return Budget(category: category, limit: limit, spent: _spentByCategory(from)[category] ?? 0);
  }

  void removeBudget(String category, {String? month}) =>
      _addChange(category, _LimitChange(month ?? _currentKey, null));

  void _addChange(String category, _LimitChange change) {
    final list = [...?_limits[category]]..removeWhere((c) => c.from == change.from);
    list.add(change);
    list.sort((a, b) => a.from.compareTo(b.from));
    _limits[category] = list;
  }

  // Dashboard ----------------------------------------------------------

  /// The summary of [month] (null = this month). The current month only lists
  /// days up to today; earlier months list every day.
  DashboardSummary summary({String? month}) {
    final key = month ?? _currentKey;
    final confirmed = _confirmedIn(key).toList();
    final byCategory = _spentByCategory(key);
    final previous = _spentByCategory(shiftMonth(key, -1));
    final perDay = <int, double>{};
    for (final r in confirmed) {
      final d = r.date?.day ?? _now.day;
      perDay[d] = (perDay[d] ?? 0) + _spend(r);
    }
    final total = byCategory.values.fold<double>(0, (a, b) => a + b);
    final lastDay = key == _currentKey ? _now.day : daysInMonth(key);
    return DashboardSummary(
      month: key,
      total: total,
      previousTotal: previous.values.fold<double>(0, (a, b) => a + b),
      receiptCount: confirmed.length,
      byCategory: [for (final e in byCategory.entries) CategorySpend(category: e.key, amount: e.value)],
      daily: [for (var d = 1; d <= lastDay; d++) DailySpend(day: d, amount: perDay[d] ?? 0)],
      previousByCategory: [for (final e in previous.entries) CategorySpend(category: e.key, amount: e.value)],
    );
  }

  /// Totals of the [months] months ending with this one, oldest first (the trends chart).
  List<MonthTotal> trend({int months = 6}) {
    final keys = [for (var back = months - 1; back >= 0; back--) shiftMonth(_currentKey, -back)];
    return [for (final k in keys) MonthTotal(month: k, total: summary(month: k == _currentKey ? null : k).total)];
  }

  // Helpers ------------------------------------------------------------

  Iterable<Receipt> _confirmedIn(String key) => _receipts.where((r) {
        if (r.status != ReceiptStatus.confirmed) return false;
        final d = r.date;
        if (d == null) return key == _currentKey; // an undated receipt counts for now
        return monthKey(d) == key;
      });

  double _spend(Receipt r) => r.items.isEmpty ? (r.total ?? 0) : r.itemsSum;

  Map<String, double> _spentByCategory(String key) {
    final out = <String, double>{};
    for (final r in _confirmedIn(key)) {
      if (r.items.isEmpty) {
        out['Other'] = (out['Other'] ?? 0) + (r.total ?? 0);
        continue;
      }
      for (final i in r.items) {
        final c = i.category ?? 'Other';
        out[c] = (out[c] ?? 0) + i.price * i.quantity;
      }
    }
    return out;
  }

  /// [daysAgo] days before today, kept inside the current month so the demo
  /// still looks right in the first days of a month.
  DateTime _day(int daysAgo) {
    final day = _now.day - daysAgo;
    return DateTime(_now.year, _now.month, day < 1 ? 1 : day);
  }

  /// Three earlier months of confirmed receipts. Amounts are scaled a little
  /// per month so the months differ and the comparison card shows ups and downs.
  List<Receipt> _history(DateTime now) {
    const scale = [1.12, 0.94, 1.2, 1.05, 0.88]; // 1 to 5 months back
    final out = <Receipt>[];
    for (var back = 1; back <= scale.length; back++) {
      final key = shiftMonth(monthKey(now), -back);
      final start = monthStart(key);
      final last = daysInMonth(key);
      for (var n = 0; n < _historyTemplates.length; n++) {
        final t = _historyTemplates[n];
        final price = (t.price * scale[back - 1] / 10).round() * 10.0;
        final id = 'demo-h$back-$n';
        out.add(Receipt(
          id: id,
          status: ReceiptStatus.confirmed,
          merchant: t.merchant,
          total: price,
          date: DateTime(start.year, start.month, t.day > last ? last : t.day),
          imageUrl: 'demo://$id',
          items: [ReceiptItem(name: t.item, price: price, category: t.category)],
        ));
      }
    }
    out.sort((a, b) => b.date!.compareTo(a.date!));
    return out;
  }

  List<Receipt> _seed(DateTime now) {
    Receipt r(
      String id,
      ReceiptStatus status,
      String? merchant,
      int daysAgo,
      double? total,
      List<ReceiptItem> items,
    ) =>
        Receipt(
          id: id,
          status: status,
          merchant: merchant,
          total: total,
          date: status == ReceiptStatus.failed ? null : _day(daysAgo),
          imageUrl: 'demo://$id',
          items: items,
        );

    const confirmed = ReceiptStatus.confirmed;
    return [
      r('demo-1', ReceiptStatus.needsReview, 'Corner Mart', 0, 1384, const [
        ReceiptItem(name: 'Basmati rice 5kg', price: 640, category: 'Groceries'),
        ReceiptItem(name: 'Toned milk 1L', price: 70, quantity: 2, category: 'Groceries'),
        ReceiptItem(name: 'Dish soap', price: 210, category: 'Shopping'),
        ReceiptItem(name: 'Face wash', price: 294, category: 'Health'),
      ]),
      r('demo-2', ReceiptStatus.processing, 'Metro Fuel', 0, null, const []),
      r('demo-3', ReceiptStatus.needsReview, 'Local Bakery', 1, 600, const [
        ReceiptItem(name: 'Brown bread', price: 120, category: 'Groceries'),
        ReceiptItem(name: 'Chocolate cake', price: 380, category: 'Dining'),
        ReceiptItem(name: 'Cookies', price: 120, category: 'Groceries'),
      ]),
      r('demo-4', confirmed, 'Fresh Basket', 1, 2260, const [
        ReceiptItem(name: 'Vegetables', price: 640, category: 'Groceries'),
        ReceiptItem(name: 'Eggs tray', price: 420, category: 'Groceries'),
        ReceiptItem(name: 'Atta 10kg', price: 1200, category: 'Groceries'),
      ]),
      r('demo-5', confirmed, 'Sher Restaurant', 2, 3450, const [
        ReceiptItem(name: 'Thali set', price: 850, quantity: 3, category: 'Dining'),
        ReceiptItem(name: 'Drinks', price: 900, category: 'Dining'),
      ]),
      r('demo-6', ReceiptStatus.failed, null, 2, null, const []),
      r('demo-7', confirmed, 'Metro Fuel', 3, 3200, const [
        ReceiptItem(name: 'Petrol 30L', price: 3200, category: 'Transport'),
      ]),
      r('demo-8', confirmed, 'Big Mart', 5, 7500, const [
        ReceiptItem(name: 'Rice 25kg', price: 3800, category: 'Groceries'),
        ReceiptItem(name: 'Cooking oil 5L', price: 1450, category: 'Groceries'),
        ReceiptItem(name: 'Lentils 2kg', price: 480, category: 'Groceries'),
        ReceiptItem(name: 'Tea 500g', price: 620, category: 'Groceries'),
        ReceiptItem(name: 'Detergent', price: 1150, category: 'Shopping'),
      ]),
      r('demo-9', confirmed, 'QFX Cinemas', 6, 1850, const [
        ReceiptItem(name: 'Movie tickets', price: 600, quantity: 2, category: 'Entertainment'),
        ReceiptItem(name: 'Popcorn and drinks', price: 650, category: 'Entertainment'),
      ]),
      r('demo-10', confirmed, 'Hill View Cafe', 7, 950, const [
        ReceiptItem(name: 'Momo', price: 450, category: 'Dining'),
        ReceiptItem(name: 'Coffee', price: 250, quantity: 2, category: 'Dining'),
      ]),
      r('demo-11', confirmed, 'Daraz order', 8, 2400, const [
        ReceiptItem(name: 'Earphones', price: 2400, category: 'Shopping'),
      ]),
      // Two receipts that look like the same purchase, for the duplicate alert.
      r('demo-12', confirmed, 'Corner Mart', 8, 640, const [
        ReceiptItem(name: 'Basmati rice 5kg', price: 640, category: 'Groceries'),
      ]),
      r('demo-13', confirmed, 'Corner Mart', 8, 640, const [
        ReceiptItem(name: 'Basmati rice 5kg', price: 640, category: 'Groceries'),
      ]),
      r('demo-14', confirmed, 'City Pharmacy', 9, 1544, const [
        ReceiptItem(name: 'Vitamins', price: 1250, category: 'Health'),
        ReceiptItem(name: 'Face wash', price: 294, category: 'Health'),
      ]),
      r('demo-15', confirmed, 'NEA electricity', 10, 2950, const [
        ReceiptItem(name: 'Electricity bill', price: 2950, category: 'Bills'),
      ]),
      r('demo-16', confirmed, 'Namaste Supermarket', 11, 4100, const [
        ReceiptItem(name: 'Fruits', price: 1600, category: 'Groceries'),
        ReceiptItem(name: 'Dairy', price: 1350, category: 'Groceries'),
        ReceiptItem(name: 'Snacks', price: 1150, category: 'Groceries'),
      ]),
      r('demo-17', confirmed, 'Nepal Telecom', 12, 2300, const [
        ReceiptItem(name: 'Internet bill', price: 1800, category: 'Bills'),
        ReceiptItem(name: 'Mobile top-up', price: 500, category: 'Bills'),
      ]),
    ];
  }
}

class _HistoryTemplate {
  const _HistoryTemplate(this.day, this.merchant, this.category, this.item, this.price);
  final int day;
  final String merchant;
  final String category;
  final String item;
  final double price;
}

const List<_HistoryTemplate> _historyTemplates = [
  _HistoryTemplate(2, 'Big Mart', 'Groceries', 'Monthly groceries', 6200),
  _HistoryTemplate(4, 'Sher Restaurant', 'Dining', 'Family dinner', 2400),
  _HistoryTemplate(6, 'Metro Fuel', 'Transport', 'Petrol', 3000),
  _HistoryTemplate(8, 'Fresh Basket', 'Groceries', 'Vegetables and eggs', 1800),
  _HistoryTemplate(9, 'NEA electricity', 'Bills', 'Electricity bill', 2700),
  _HistoryTemplate(12, 'Daraz order', 'Shopping', 'Kitchen items', 2900),
  _HistoryTemplate(14, 'City Pharmacy', 'Health', 'Medicines', 1300),
  _HistoryTemplate(16, 'Hill View Cafe', 'Dining', 'Coffee and momo', 1100),
  _HistoryTemplate(19, 'Nepal Telecom', 'Bills', 'Internet bill', 1800),
  _HistoryTemplate(22, 'QFX Cinemas', 'Entertainment', 'Movie night', 1600),
  _HistoryTemplate(25, 'Namaste Supermarket', 'Groceries', 'Fruits and dairy', 3300),
  _HistoryTemplate(28, 'Metro Fuel', 'Transport', 'Petrol', 2600),
];

class _ScanSample {
  const _ScanSample(this.merchant, this.total, this.items);
  final String merchant;
  final double total;
  final List<ReceiptItem> items;
}

/// What a "scan" in demo mode turns into. Totals are slightly off on purpose,
/// so the review screen has something to show.
const List<_ScanSample> _scanSamples = [
  _ScanSample('Sunrise Mart', 1190, [
    ReceiptItem(name: 'Bread', price: 90, category: 'Groceries'),
    ReceiptItem(name: 'Butter', price: 260, category: 'Groceries'),
    ReceiptItem(name: 'Shampoo', price: 740, category: 'Health'),
  ]),
  _ScanSample('Newa Kitchen', 1750, [
    ReceiptItem(name: 'Chatamari', price: 450, quantity: 2, category: 'Dining'),
    ReceiptItem(name: 'Lassi', price: 250, quantity: 2, category: 'Dining'),
    ReceiptItem(name: 'Service charge', price: 300, category: 'Dining'),
  ]),
];
