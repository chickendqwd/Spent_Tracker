import 'package:hive/hive.dart';

part 'recurring_rule.g.dart';

/// 周期记账频率：每周 / 每月 / 每年。
enum RecurringFrequency {
  weekly('每周'),
  monthly('每月'),
  yearly('每年');

  const RecurringFrequency(this.label);
  final String label;

  static RecurringFrequency fromIndex(int v) => switch (v) {
        1 => RecurringFrequency.monthly,
        2 => RecurringFrequency.yearly,
        _ => RecurringFrequency.weekly,
      };
}

/// 周期记账规则（v2）：按 frequency + dayValue 周期性提醒「待记」，不自动入账。
@HiveType(typeId: 4)
class RecurringRule extends HiveObject {
  RecurringRule({
    required this.type,
    required this.amount,
    this.categoryId,
    this.note,
    this.currency = 'SGD',
    required this.frequency,
    required this.dayValue,
    required this.startDate,
    this.active = true,
  });

  /// 0=支出，1=收入（对应 TransactionType.index）。
  @HiveField(0)
  int type;

  /// 金额（整数分，按 currency 币种）。
  @HiveField(1)
  int amount;

  /// 分类外键（可为空 → 未分类）。
  @HiveField(2)
  int? categoryId;

  /// 备注（可选）。
  @HiveField(3)
  String? note;

  /// 币种代码（默认 SGD）。
  @HiveField(4)
  String currency;

  /// 0=weekly，1=monthly，2=yearly（对应 RecurringFrequency.index）。
  @HiveField(5)
  int frequency;

  /// weekly：周几（周一=1 … 周日=7）；monthly/yearly：几号（1-31）。
  @HiveField(6)
  int dayValue;

  /// 开始日期 yyyy-MM-dd。
  @HiveField(7)
  String startDate;

  /// 是否启用（停用后不再提醒）。
  @HiveField(8)
  bool active;

  RecurringFrequency get recurringFrequency =>
      RecurringFrequency.fromIndex(frequency);
}
