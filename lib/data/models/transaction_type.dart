/// 账目类型：支出 / 收入。
enum TransactionType {
  expense('支出'),
  income('收入');

  const TransactionType(this.label);

  /// 展示名
  final String label;

  /// 持久化索引与枚举声明顺序一致（0=支出，1=收入），请勿调整枚举顺序。
  static TransactionType fromIndex(int v) =>
      v == 0 ? TransactionType.expense : TransactionType.income;
}
