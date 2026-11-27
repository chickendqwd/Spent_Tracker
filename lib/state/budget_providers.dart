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

/// 预算全局默认币种的设置键。值存币种 code；键不存在 = 跟随基准币种。
const _budgetCurrencyStorageKey = 'budgetCurrencyCode';

/// 预算默认币种设置（v3.4.1）。null 表示跟随当前基准币种。
class BudgetCurrencyNotifier extends Notifier<String?> {
  @override
  String? build() {
    final raw = Db.settings.get(_budgetCurrencyStorageKey);
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  Future<void> set(String? code) async {
    if (code == null || code.isEmpty) {
      await Db.settings.delete(_budgetCurrencyStorageKey);
    } else {
      await Db.settings.put(_budgetCurrencyStorageKey, code);
    }
    state = (code == null || code.isEmpty) ? null : code;
  }
}

final budgetCurrencyProvider =
    NotifierProvider<BudgetCurrencyNotifier, String?>(
      BudgetCurrencyNotifier.new,
    );

/// 新增预算时的默认币种：全局设置优先，未设置则跟随当前基准币种。
String defaultBudgetCurrencyCode(List<Currency> currencies, String? setting) =>
    (setting == null || setting.isEmpty) ? baseCodeOf(currencies) : setting;

/// 本月生效预算：当月未设置时沿用最近一个有预算的月份。
final effectiveBudgetsProvider = Provider<List<Budget>>((ref) {
  ref.watch(budgetProvider);
  final month = DateUtil.monthKey(DateTime.now());
  return const BudgetRepository().effectiveForMonth(month);
});

/// 预算金额折算为当前基准币种分（v3.4.1 起预算可自选币种）。
///
/// 预算金额与币种一起存储，展示/比较前换算到基准；预算本身不冻结汇率，
/// 因为它是「这个月打算花多少」的目标值，跟着币种走才对。
int budgetCentsInBase(
  List<Currency> currencies,
  int amount,
  String currencyCode,
) => transactionCentsInBase(currencies, amount, currencyCode);

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
    expense += transactionCentsInBase(
      currencies,
      t.amount,
      t.currency,
      rateSnapshot: t.rateToSgd,
    );
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
    byId[k] = (byId[k] ?? 0) +
        transactionCentsInBase(
          currencies,
          t.amount,
          t.currency,
          rateSnapshot: t.rateToSgd,
        );
  }
  return byId;
});
