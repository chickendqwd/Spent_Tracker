import '../models/budget.dart';
import 'database.dart';

/// 预算仓库（v2）。
class BudgetRepository {
  const BudgetRepository();

  /// 全部预算（按月份倒序，同一月内总预算在前）。
  List<Budget> getAll() {
    final list = Db.budgets.values.toList();
    list.sort((a, b) {
      final byMonth = b.month.compareTo(a.month);
      if (byMonth != 0) return byMonth;
      return a.type.compareTo(b.type);
    });
    return list;
  }

  Future<int> add(Budget budget) => Db.budgets.add(budget);

  Future<void> update(Budget budget) => budget.save();

  Future<void> delete(int key) => Db.budgets.delete(key);

  /// 指定月份的预算；该月未设置时，沿用最近一个设有预算的月份。
  /// 返回 null 表示从未设置过预算。
  List<Budget> effectiveForMonth(String month) {
    final all = getAll();
    // 收集 <= month 的所有预算月份，取最近的一个
    final months = <String>{
      for (final b in all)
        if (b.month.compareTo(month) <= 0) b.month,
    };
    if (months.isEmpty) return const [];
    // months 已含排序，取最大（最近）的一个
    final effectiveMonth =
        months.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    return all.where((b) => b.month == effectiveMonth).toList();
  }
}
