import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/utils/date_util.dart';
import '../data/db/budget_repository.dart';
import '../data/db/database.dart';
import '../data/models/budget.dart';
import '../data/models/currency.dart';
import '../data/models/transaction_type.dart';
import 'currency_providers.dart';
import 'transaction_providers.dart';

/// 预算盒变更事件流。
final budgetsBoxEventsProvider = StreamProvider<BoxEvent>((ref) {
  return Db.budgets.watch();
});

/// 预算状态：监听 Hive 盒子变化。
class BudgetNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() {
    ref.watch(budgetsBoxEventsProvider);
    return const BudgetRepository().getAll();
  }

  Future<int> add(Budget budget) => const BudgetRepository().add(budget);

  Future<void> update(Budget budget) => const BudgetRepository().update(budget);

  Future<void> remove(int key) => const BudgetRepository().delete(key);
}

final budgetProvider = NotifierProvider<BudgetNotifier, List<Budget>>(
  BudgetNotifier.new,
);

/// 本月生效预算：当月未设置时沿用最近一个有预算的月份。
final effectiveBudgetsProvider = Provider<List<Budget>>((ref) {
  ref.watch(budgetProvider);
  final month = DateUtil.monthKey(DateTime.now());
  return const BudgetRepository().effectiveForMonth(month);
});

/// 预算金额的存储口径是「SGD 分」（历史数据不改写）。
/// 展示与超支比较前换算到当前基准币种；基准为 SGD 时原样返回。
int budgetCentsInBase(List<Currency> currencies, int sgdCents) =>
    toBaseCents(currencies, sgdCents, 'SGD');

/// 录入预算时把「当前基准币种分」转回「SGD 分」存储。
int budgetCentsToSgd(List<Currency> currencies, int baseCents) {
  final baseRate = baseRateOf(currencies);
  if (baseRate <= 0) return baseCents;
  return (baseCents * baseRate).round();
}

/// 本月生效的总预算（可能为 null，表示未设置）。
final totalBudgetProvider = Provider<Budget?>((ref) {
  final effective = ref.watch(effectiveBudgetsProvider);
  for (final b in effective) {
    if (b.type == BudgetType.total.index) return b;
  }
  return null;
});

/// 本月生效的分类预算（按 categoryId）。
final categoryBudgetProvider = Provider<Map<int, Budget>>((ref) {
  final effective = ref.watch(effectiveBudgetsProvider);
  return {
    for (final b in effective)
      if (b.type == BudgetType.category.index && b.categoryId != null)
        b.categoryId!: b,
  };
});

/// 本月支出总额（当前基准币种分）。预算按「月」，进度条与超支判定均用本月口径。
final thisMonthExpenseProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionProvider);
  final currencies = ref.watch(currencyProvider);
  final month = DateUtil.monthKey(DateTime.now());
  var expense = 0;
  for (final t in transactions) {
    if (t.transactionType != TransactionType.expense) continue;
    if (DateUtil.monthKey(DateUtil.fromDayKey(t.date)) != month) continue;
    expense += toBaseCents(currencies, t.amount, t.currency);
  }
  return expense;
});

/// 本月各分类支出（当前基准币种分；key=-1 表示未分类）。
final thisMonthExpenseByCategoryProvider = Provider<Map<int, int>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final currencies = ref.watch(currencyProvider);
  final month = DateUtil.monthKey(DateTime.now());
  const uncategorizedKey = -1;
  final byId = <int, int>{};
  for (final t in transactions) {
    if (t.transactionType != TransactionType.expense) continue;
    if (DateUtil.monthKey(DateUtil.fromDayKey(t.date)) != month) continue;
    final k = t.categoryId ?? uncategorizedKey;
    byId[k] = (byId[k] ?? 0) + toBaseCents(currencies, t.amount, t.currency);
  }
  return byId;
});
