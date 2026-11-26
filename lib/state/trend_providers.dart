import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/trend_analytics.dart';
import 'currency_providers.dart';
import 'transaction_providers.dart';

/// 趋势图当前区间：v3.3.1 起默认「本周」逐日，便于当周回顾。
class TrendRangeNotifier extends Notifier<TrendRange> {
  @override
  TrendRange build() => TrendRange.week;

  void set(TrendRange value) => state = value;
}

final trendRangeProvider =
    NotifierProvider<TrendRangeNotifier, TrendRange>(TrendRangeNotifier.new);

/// 所选区间内按步长采样后的收支桶（金额为基准币种分）。
///
/// 与总览顶部的时间筛选相互独立：顶部筛选只管总账与明细列表。
final trendProvider = Provider<List<TrendBucket>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final currencies = ref.watch(currencyProvider);
  final range = ref.watch(trendRangeProvider);

  return computeTrendBuckets(
    ranges: trendBucketRanges(range, DateTime.now()),
    transactions: transactions,
    toCents: (amount, code) => toBaseCents(currencies, amount, code),
  );
});
