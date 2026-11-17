import 'package:hive/hive.dart';

part 'currency.g.dart';

/// 币种配置与对基准币种 SGD 的汇率。
/// Hive key 为该币种的 code（如 'CNY' / 'SGD' / 'MYR'）。
@HiveType(typeId: 2)
class Currency {
  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rateToSgd,
    this.isBase = false,
  });

  /// 币种代码（如 CNY / SGD / MYR），同时作为 Hive key。
  @HiveField(0)
  String code;

  /// 中文名（如 人民币 / 新加坡元 / 马来西亚林吉特）。
  @HiveField(1)
  String name;

  /// 展示符号（¥ / S$ / RM）。
  @HiveField(2)
  String symbol;

  /// 1 单位本币 = rateToSgd 单位 SGD（基准币种自身为 1）。
  @HiveField(3)
  double rateToSgd;

  /// 是否基准币种（SGD）。
  @HiveField(4)
  bool isBase;
}
