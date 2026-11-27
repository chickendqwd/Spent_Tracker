import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/db/currency_repository.dart';
import '../data/db/database.dart';
import '../data/models/currency.dart';

/// 币种盒变更事件流。
final currenciesBoxEventsProvider = StreamProvider<BoxEvent>((ref) {
  return Db.currencies.watch();
});

/// 币种状态：监听 Hive 盒子变化。
class CurrencyNotifier extends Notifier<List<Currency>> {
  @override
  List<Currency> build() {
    ref.watch(currenciesBoxEventsProvider);
    return const CurrencyRepository().getAll();
  }

  Currency get base {
    final list = state;
    for (final c in list) {
      if (c.isBase) return c;
    }
    return list.first;
  }

  /// 修改某币种汇率（金额为「1 单位本币 = ? SGD」）。
  Future<void> updateRate(String code, double rate) =>
      const CurrencyRepository().updateRate(code, rate);

  /// 批量更新汇率（联网更新用）。
  Future<void> updateRates(Map<String, double> rates) =>
      const CurrencyRepository().updateRates(rates);

  /// 切换基准币种：只改标记，不改任何汇率与历史数据。
  Future<void> setBase(String code) =>
      const CurrencyRepository().setBase(code);
}

final currencyProvider = NotifierProvider<CurrencyNotifier, List<Currency>>(
  CurrencyNotifier.new,
);

/// 基准币种（默认 SGD，可在货币页切换）。
///
/// 必须 watch 币种列表本身：notifier 上的 `base` getter 读的是内部 state，
/// 只 watch notifier 实例不会随列表变化重建，切换基准后星标/符号就会停在上一个基准。
final baseCurrencyProvider = Provider<Currency>((ref) {
  final list = ref.watch(currencyProvider);
  for (final c in list) {
    if (c.isBase) return c;
  }
  return list.first;
});

/// 某币种对 SGD 的汇率（缺失时按 1 处理）。
double rateOf(List<Currency> currencies, String code) {
  for (final c in currencies) {
    if (c.code == code) return c.rateToSgd;
  }
  return 1.0;
}

/// 当前基准币种的 code（无 isBase 标记时回退列表首个）。
String baseCodeOf(List<Currency> currencies) {
  for (final c in currencies) {
    if (c.isBase) return c.code;
  }
  return currencies.isEmpty ? 'SGD' : currencies.first.code;
}

/// 基准币种自身对 SGD 的汇率（基准为 SGD 时即 1）。
double baseRateOf(List<Currency> currencies) =>
    rateOf(currencies, baseCodeOf(currencies));

/// 「1 单位 code = ? 基准币种」，用于货币页展示与录入。
double rateToBaseOf(List<Currency> currencies, String code) {
  final baseRate = baseRateOf(currencies);
  if (baseRate <= 0) return 1.0;
  return rateOf(currencies, code) / baseRate;
}

/// 某币种的展示符号；币种缺失时回退到当前基准币种符号。
String symbolOf(List<Currency> currencies, String code) {
  for (final c in currencies) {
    if (c.code == code) return c.symbol;
  }
  final baseCode = baseCodeOf(currencies);
  for (final c in currencies) {
    if (c.code == baseCode) return c.symbol;
  }
  return 'S\$';
}

/// 把「某币种金额（分）」换算为「当前基准币种金额（分）」，四舍五入。
///
/// 以 SGD 为中间货币交叉换算：amount × rate(code) / rate(base)。
/// 基准为 SGD 时退化为 amount × rate(code)，与 v2 口径一致。
int toBaseCents(List<Currency> currencies, int amount, String currencyCode) {
  if (currencyCode.isEmpty) return amount;
  if (currencyCode == baseCodeOf(currencies)) return amount;
  final rate = rateOf(currencies, currencyCode);
  final baseRate = baseRateOf(currencies);
  if (rate <= 0 || baseRate <= 0) return amount;
  return (amount * rate / baseRate).round();
}

/// 单笔账目折算为当前基准币种分（v3.4.1）。
///
/// 优先用记账时的汇率快照 [rateSnapshot]（1 单位本币 = ? SGD），
/// 这样之后修改外币汇率不会改变历史账目的金额。
/// 无快照的旧数据（尚未迁移）回退当前汇率，与 v3.4 行为一致。
/// 基准币种自身仍用当前汇率换算：切换基准时历史值会按展示换算，属预期。
int transactionCentsInBase(
  List<Currency> currencies,
  int amount,
  String currencyCode, {
  double? rateSnapshot,
}) {
  if (currencyCode.isEmpty) return amount;
  final baseRate = baseRateOf(currencies);
  if (baseRate <= 0) return amount;
  if (rateSnapshot != null && rateSnapshot > 0) {
    return (amount * rateSnapshot / baseRate).round();
  }
  return toBaseCents(currencies, amount, currencyCode);
}
