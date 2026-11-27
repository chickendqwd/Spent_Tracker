import 'package:hive/hive.dart';

part 'budget.g.dart';

/// 预算类型：总预算 / 分类预算。
enum BudgetType {
  total('总预算'),
  category('分类预算');

  const BudgetType(this.label);
  final String label;

  static BudgetType fromIndex(int v) =>
      v == 0 ? BudgetType.total : BudgetType.category;
}

/// 预算表（v2）：按「月」生效。
/// 当月未设置时，沿用最近一个有预算的月份；从未设置则不显示进度条。
@HiveType(typeId: 3)
class Budget extends HiveObject {
  Budget({
    required this.type,
    this.categoryId,
    required this.month,
    required this.amount,
    this.currency,
  });

  /// 0=总预算，1=分类预算（对应 BudgetType.index，勿调整顺序）。
  @HiveField(0)
  int type;

  /// type=category 时的分类外键；type=total 为 null。
  @HiveField(1)
  int? categoryId;

  /// 预算所属月份 yyyy-MM。
  @HiveField(2)
  String month;

  /// 预算金额（整数分），以 [currency] 计量。
  /// v3.4.1 之前的旧数据统一是「SGD 分」，读取时 currency 为空按 SGD 处理。
  @HiveField(3)
  int amount;

  /// 预算的录入币种（v3.4.1 新增）。为空表示旧数据，按 SGD 理解。
  @HiveField(4)
  String? currency;

  /// 预算币种代码，旧数据回退 SGD。
  String get currencyCode => currency ?? 'SGD';

  BudgetType get budgetType => BudgetType.fromIndex(type);
}
