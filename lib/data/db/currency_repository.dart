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

  /// 基准币种（isBase=true，默认 SGD；无则回退第一个）。
  Currency get base {
    for (final c in Db.currencies.values) {
      if (c.isBase) return c;
    }
    return Db.currencies.values.first;
  }

  Currency? byCode(String code) => Db.currencies.get(code);

  /// 修改某币种汇率（存的是「1 单位本币 = ? SGD」）。
  /// SGD 是换算锚点，其汇率恒为 1，不接受外部修改。
  Future<void> updateRate(String code, double rate) async {
    final c = Db.currencies.get(code);
    if (c == null) return;
    c.rateToSgd = code == 'SGD' ? 1.0 : rate;
    await Db.currencies.put(code, c);
  }

  /// 批量更新汇率（联网更新用）。code→rate 映射；跳过 SGD 锚点与缺失项。
  Future<void> updateRates(Map<String, double> rates) async {
    for (final entry in rates.entries) {
      if (entry.key == 'SGD') continue;
      final c = Db.currencies.get(entry.key);
      if (c == null || entry.value <= 0) continue;
      c.rateToSgd = entry.value;
      await Db.currencies.put(entry.key, c);
    }
  }

  /// 切换基准币种：只改 isBase 标记，不改任何汇率、预算或历史账目。
  /// 旧基准自动变回普通币种。
  Future<void> setBase(String code) async {
    if (!Db.currencies.containsKey(code)) return;
    for (final c in Db.currencies.values) {
      final next = c.code == code;
      if (c.isBase == next) continue;
      c.isBase = next;
      await Db.currencies.put(c.code, c);
    }
  }
}
