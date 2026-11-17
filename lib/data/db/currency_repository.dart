import '../models/currency.dart';
import 'database.dart';

/// 币种与汇率仓库。
class CurrencyRepository {
  const CurrencyRepository();

  /// 全部币种（按 code 排序）
  List<Currency> getAll() {
    final list = Db.currencies.values.toList();
    list.sort((a, b) => a.code.compareTo(b.code));
    return list;
  }

  /// 基准币种（isBase=true，预期为 SGD；无则回退第一个）。
  Currency get base {
    for (final c in Db.currencies.values) {
      if (c.isBase) return c;
    }
    return Db.currencies.values.first;
  }

  Currency? byCode(String code) => Db.currencies.get(code);

  /// 修改某币种汇率（基准币种应恒为 1）。
  Future<void> updateRate(String code, double rate) async {
    final c = Db.currencies.get(code);
    if (c == null) return;
    c.rateToSgd = c.isBase ? 1.0 : rate;
    await Db.currencies.put(code, c);
  }

  /// 批量更新汇率（联网更新用）。code→rate 映射；跳过基准币种与缺失项。
  Future<void> updateRates(Map<String, double> rates) async {
    for (final entry in rates.entries) {
      final c = Db.currencies.get(entry.key);
      if (c == null || c.isBase) continue;
      c.rateToSgd = entry.value;
      await Db.currencies.put(entry.key, c);
    }
  }
}
