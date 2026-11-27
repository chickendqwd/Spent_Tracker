import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/models/transaction_type.dart';
import 'category_providers.dart';
import 'currency_providers.dart';
import 'time_range_providers.dart';
import 'transaction_providers.dart';

/// 某分类在所选时间区间内的金额项（金额为基准币种 SGD 分）。
class CategoryShare {
  const CategoryShare({required this.category, required this.amountCents});

  /// null 表示「未分类」
  final Category? category;
  final int amountCents;
}

/// 所选时间区间内的收支汇总（金额统一为基准币种 SGD 分）。
class RangeSummary {
  const RangeSummary({
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
    required this.expenseByCategory,
    required this.incomeByCategory,
  });

  final int totalExpense;
  final int totalIncome;
  final int balance;

  /// 按金额降序
  final List<CategoryShare> expenseByCategory;
  final List<CategoryShare> incomeByCategory;
}

/// 汇总：总支出、总收入、结余、支出/收入分类占比。
/// 按所选时间区间聚合，金额换算为基准币种（SGD）。
final rangeSummaryProvider = Provider<RangeSummary>((ref) {
  final transactions = ref.watch(transactionProvider);
  final categories = ref.watch(categoryProvider);
  final range = ref.watch(dateRangeProvider);
  final currencies = ref.watch(currencyProvider);

  var expense = 0;
  var income = 0;
  final expenseByCategoryId = <int, int>{};
  final incomeByCategoryId = <int, int>{};
  const uncategorizedKey = -1;

  for (final t in transactions) {
    if (!range.containsKey(t.date)) continue;
    final cents = transactionCentsInBase(
      currencies,
      t.amount,
      t.currency,
      rateSnapshot: t.rateToSgd,
    );
    if (t.transactionType == TransactionType.expense) {
      expense += cents;
      final k = t.categoryId ?? uncategorizedKey;
      expenseByCategoryId[k] = (expenseByCategoryId[k] ?? 0) + cents;
    } else {
      income += cents;
      final k = t.categoryId ?? uncategorizedKey;
      incomeByCategoryId[k] = (incomeByCategoryId[k] ?? 0) + cents;
    }
  }

  final categoryByKey = {for (final c in categories) c.key as int: c};
  List<CategoryShare> buildShares(Map<int, int> byId) {
    final shares = byId.entries
        .map(
          (e) => CategoryShare(
            category: e.key == uncategorizedKey ? null : categoryByKey[e.key],
            amountCents: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
    return shares;
  }

  return RangeSummary(
    totalExpense: expense,
    totalIncome: income,
    balance: income - expense,
    expenseByCategory: buildShares(expenseByCategoryId),
    incomeByCategory: buildShares(incomeByCategoryId),
  );
});

/// 区间内最近记录（不限类型，按时间倒序的前 N 条）。
final rangeRecentTransactionsProvider =
    Provider<List<Transaction>>((ref) {
  const n = 5;
  final transactions = ref.watch(transactionProvider);
  final range = ref.watch(dateRangeProvider);
  final inRange = transactions.where((t) => range.containsKey(t.date)).toList();
  return inRange.length <= n ? inRange : inRange.sublist(0, n);
});
