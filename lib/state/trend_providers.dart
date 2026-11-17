import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_util.dart';
import '../data/models/transaction_type.dart';
import 'currency_providers.dart';
import 'transaction_providers.dart';

/// 某月收支点（金额为基准币种 SGD 分）。
class MonthlyPoint {
  const MonthlyPoint({
    required this.month,
    required this.expense,
    required this.income,
  });

  /// yyyy-MM
  final String month;
  final int expense;
  final int income;
}

/// 趋势图展示月数：6 / 12。
class TrendMonthCountNotifier extends Notifier<int> {
  @override
  int build() => 6;

  void set(int value) => state = value;
}

final trendMonthCountProvider =
    NotifierProvider<TrendMonthCountNotifier, int>(TrendMonthCountNotifier.new);

/// 最近 N 个月收支趋势（含当前月；无数据月份画 0）。
final trendProvider = Provider<List<MonthlyPoint>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final currencies = ref.watch(currencyProvider);
  final count = ref.watch(trendMonthCountProvider);

  final now = DateTime.now();
  final months = List<String>.generate(count, (i) {
    final d = DateTime(now.year, now.month - (count - 1 - i), 1);
    return DateUtil.monthKey(d);
  });
  final map = <String, List<int>>{for (final m in months) m: [0, 0]};

  for (final t in transactions) {
    final key = DateUtil.monthKey(DateUtil.fromDayKey(t.date));
    final bucket = map[key];
    if (bucket == null) continue;
    final cents = toBaseCents(currencies, t.amount, t.currency);
    if (t.transactionType == TransactionType.expense) {
      bucket[0] += cents;
    } else {
      bucket[1] += cents;
    }
  }

  return [
    for (final m in months)
      MonthlyPoint(month: m, expense: map[m]![0], income: map[m]![1]),
  ];
});
