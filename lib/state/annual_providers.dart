import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_util.dart';
import '../data/models/transaction_type.dart';
import 'category_providers.dart';
import 'currency_providers.dart';
import 'summary_providers.dart';
import 'transaction_providers.dart';
import 'trend_providers.dart';

/// 某一年的收支汇总（金额统一为基准币种 SGD 分）。
class AnnualSummary {
  const AnnualSummary({
    required this.year,
    required this.totalExpense,
    required this.totalIncome,
    required this.months,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.recordCount,
  });

  final int year;
  final int totalExpense;
  final int totalIncome;

  /// 1-12 月，无数据月份为 0
  final List<MonthlyPoint> months;

  /// 按金额降序
  final List<CategoryShare> expenseByCategory;
  final List<CategoryShare> incomeByCategory;

  /// 该年记账笔数
  final int recordCount;

  int get balance => totalIncome - totalExpense;

  /// 支出最高的月份（1-12；全年无支出返回 0）
  int get peakExpenseMonth {
    var best = 0;
    var month = 0;
    for (final m in months) {
      if (m.expense > best) {
        best = m.expense;
        month = int.parse(m.month.substring(5));
      }
    }
    return month;
  }

  /// 有支出的月份数（月均支出按此计算，避免被空月份拉低）
  int get monthsWithExpense => months.where((m) => m.expense > 0).length;

  int get averageMonthlyExpense {
    final n = monthsWithExpense;
    return n == 0 ? 0 : (totalExpense / n).round();
  }
}

/// 年报展示年份：默认今年，可向前回看（不允许超过今年）。
class AnnualYearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;

  void previous() => state = state - 1;

  void next() {
    final now = DateTime.now().year;
    if (state < now) state = state + 1;
  }
}

final annualYearProvider =
    NotifierProvider<AnnualYearNotifier, int>(AnnualYearNotifier.new);

final annualSummaryProvider = Provider<AnnualSummary>((ref) {
  final year = ref.watch(annualYearProvider);
  final transactions = ref.watch(transactionProvider);
  final categories = ref.watch(categoryProvider);
  final currencies = ref.watch(currencyProvider);
  const uncategorizedKey = -1;

  final monthExpense = <int, int>{};
  final monthIncome = <int, int>{};
  final expenseByCategoryId = <int, int>{};
  final incomeByCategoryId = <int, int>{};
  var totalExpense = 0;
  var totalIncome = 0;
  var recordCount = 0;

  for (final t in transactions) {
    final d = DateUtil.fromDayKey(t.date);
    if (d.year != year) continue;
    recordCount++;
    final cents = toBaseCents(currencies, t.amount, t.currency);
    final k = t.categoryId ?? uncategorizedKey;
    if (t.transactionType == TransactionType.expense) {
      totalExpense += cents;
      monthExpense[d.month] = (monthExpense[d.month] ?? 0) + cents;
      expenseByCategoryId[k] = (expenseByCategoryId[k] ?? 0) + cents;
    } else {
      totalIncome += cents;
      monthIncome[d.month] = (monthIncome[d.month] ?? 0) + cents;
      incomeByCategoryId[k] = (incomeByCategoryId[k] ?? 0) + cents;
    }
  }

  final categoryByKey = {for (final c in categories) c.key as int: c};
  List<CategoryShare> shares(Map<int, int> byId) => byId.entries
      .map(
        (e) => CategoryShare(
          category: e.key == uncategorizedKey ? null : categoryByKey[e.key],
          amountCents: e.value,
        ),
      )
      .toList()
    ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

  return AnnualSummary(
    year: year,
    totalExpense: totalExpense,
    totalIncome: totalIncome,
    months: [
      for (var m = 1; m <= 12; m++)
        MonthlyPoint(
          month: '$year-${m.toString().padLeft(2, '0')}',
          expense: monthExpense[m] ?? 0,
          income: monthIncome[m] ?? 0,
        ),
    ],
    expenseByCategory: shares(expenseByCategoryId),
    incomeByCategory: shares(incomeByCategoryId),
    recordCount: recordCount,
  );
});
