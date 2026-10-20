import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_util.dart';
import '../data/models/category.dart';
import '../data/models/transaction_type.dart';
import 'category_providers.dart';
import 'transaction_providers.dart';

/// 某分类在当月支出中的占比项。
class CategoryShare {
  const CategoryShare({required this.category, required this.amountCents});

  /// null 表示「未分类」
  final Category? category;
  final int amountCents;
}

/// 月度总结（默认本月）。
class MonthSummary {
  const MonthSummary({
    required this.monthKey,
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
    required this.expenseByCategory,
  });

  final String monthKey;
  final int totalExpense;
  final int totalIncome;
  final int balance;

  /// 按金额降序
  final List<CategoryShare> expenseByCategory;
}

/// 月度总结：总支出、总收入、结余、支出分类占比。
final monthSummaryProvider = Provider<MonthSummary>((ref) {
  final transactions = ref.watch(transactionProvider);
  final categories = ref.watch(categoryProvider);
  final month = DateUtil.monthKey(DateTime.now());

  var expense = 0;
  var income = 0;
  final expenseByCategoryId = <int, int>{};
  const uncategorizedKey = -1;

  for (final t in transactions) {
    if (DateUtil.monthKey(DateUtil.fromDayKey(t.date)) != month) continue;
    if (t.transactionType == TransactionType.expense) {
      expense += t.amount;
      final k = t.categoryId ?? uncategorizedKey;
      expenseByCategoryId[k] = (expenseByCategoryId[k] ?? 0) + t.amount;
    } else {
      income += t.amount;
    }
  }

  final categoryByKey = {for (final c in categories) c.key as int: c};
  final shares =
      expenseByCategoryId.entries
          .map(
            (e) => CategoryShare(
              category: e.key == uncategorizedKey ? null : categoryByKey[e.key],
              amountCents: e.value,
            ),
          )
          .toList()
        ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

  return MonthSummary(
    monthKey: month,
    totalExpense: expense,
    totalIncome: income,
    balance: income - expense,
    expenseByCategory: shares,
  );
});
