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

  /// 预算金额（整数分），统一以基准币种 SGD 设定。
  @HiveField(3)
  int amount;

  BudgetType get budgetType => BudgetType.fromIndex(type);
}
