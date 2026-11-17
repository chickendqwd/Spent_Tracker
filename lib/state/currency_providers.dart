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

  /// 修改某币种汇率（基准币种恒为 1）。
  Future<void> updateRate(String code, double rate) =>
      const CurrencyRepository().updateRate(code, rate);

  /// 批量更新汇率（联网更新用）。
  Future<void> updateRates(Map<String, double> rates) =>
      const CurrencyRepository().updateRates(rates);
}

final currencyProvider = NotifierProvider<CurrencyNotifier, List<Currency>>(
  CurrencyNotifier.new,
);

/// 基准币种（SGD）。
final baseCurrencyProvider = Provider<Currency>((ref) {
  return ref.watch(currencyProvider.notifier).base;
});

/// 某币种对基准币种的汇率（缺失时按 1 处理）。
double rateOf(List<Currency> currencies, String code) {
  for (final c in currencies) {
    if (c.code == code) return c.rateToSgd;
  }
  return 1.0;
}

/// 把「某币种金额（分）」换算为「基准币种金额（分）」，四舍五入。
/// 币种缺失或为基准币种时原样返回。
int toBaseCents(List<Currency> currencies, int amount, String currencyCode) {
  final c = rateOf(currencies, currencyCode);
  if (c == 1.0 || currencyCode.isEmpty) return amount;
  return (amount * c).round();
}
