import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/utils/date_util.dart';
import '../data/db/database.dart';
import '../data/db/recurring_rule_repository.dart';
import '../data/models/recurring_rule.dart';
import '../data/models/transaction.dart';
import 'transaction_providers.dart';

/// 周期规则盒变更事件流。
final recurringRulesBoxEventsProvider = StreamProvider<BoxEvent>((ref) {
  return Db.recurringRules.watch();
});

/// 周期记账规则状态：监听 Hive 盒子变化。
class RecurringRuleNotifier extends Notifier<List<RecurringRule>> {
  @override
  List<RecurringRule> build() {
    ref.watch(recurringRulesBoxEventsProvider);
    return const RecurringRuleRepository().getAll();
  }

  Future<int> add(RecurringRule rule) =>
      const RecurringRuleRepository().add(rule);

  Future<void> update(RecurringRule rule) =>
      const RecurringRuleRepository().update(rule);

  Future<void> remove(int key) =>
      const RecurringRuleRepository().delete(key);

  /// 启停（幂等）。
  Future<void> toggleActive(RecurringRule rule) async {
    rule.active = !rule.active;
    await const RecurringRuleRepository().update(rule);
  }
}

final recurringRuleProvider =
    NotifierProvider<RecurringRuleNotifier, List<RecurringRule>>(
      RecurringRuleNotifier.new,
    );

/// 判定某天是否命中周期规则。
/// 口径：weekly 按周几（周一=1…周日=7）；monthly 按月几号；
/// yearly 为「每年 startDate 所在月份的 dayValue 号」（模型未含月份字段，以此界定，注释说明）。
///
/// v3.2：monthly / yearly 的日号按当月天数夹取——
/// 选 31 号时，4 月落到 30 日、2 月落到 28/29 日；选 29 号时平年 2 月落到 28 日。
/// 保证每月恰好命中一次，而不是在小月整月不命中。
bool ruleMatches(RecurringRule rule, DateTime day) {
  switch (rule.recurringFrequency) {
    case RecurringFrequency.weekly:
      return day.weekday == rule.dayValue;
    case RecurringFrequency.monthly:
      return day.day == _clampedDay(rule.dayValue, day.year, day.month);
    case RecurringFrequency.yearly:
      return day.month == DateUtil.fromDayKey(rule.startDate).month &&
          day.day == _clampedDay(rule.dayValue, day.year, day.month);
  }
}

/// 把「每月几号」夹到当月合法范围（31 → 小月月末；29 → 平年 2 月为 28）。
int _clampedDay(int dayValue, int year, int month) {
  final lastDay = DateTime(year, month + 1, 0).day;
  if (dayValue < 1) return 1;
  return dayValue > lastDay ? lastDay : dayValue;
}

/// 今天到期的启用规则（用于总览「今日待记」提示条）。
///
/// v3.4.1：今天已有「同类型 + 同金额 + 同币种 + 同分类」的账目时，
/// 视为这条规则今天已记，不再提示——否则记账后提示条仍留在首页。
final todayDueRulesProvider = Provider<List<RecurringRule>>((ref) {
  final rules = ref.watch(recurringRuleProvider);
  final transactions = ref.watch(transactionProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayKey = DateUtil.toDayKey(today);
  return rules
      .where(
        (r) =>
            r.active &&
            !today.isBefore(DateUtil.fromDayKey(r.startDate)) &&
            ruleMatches(r, today) &&
            !_hasTodayEntry(transactions, r, todayKey),
      )
      .toList();
});

/// 今天是否已有一笔与该规则对应的账目。
///
/// 周期规则不写入「已记」标记，只按账目本身判断：
/// 同日期、同类型、同金额、同币种、同分类即视为已记。
bool _hasTodayEntry(
  List<Transaction> transactions,
  RecurringRule rule,
  String todayKey,
) {
  for (final t in transactions) {
    if (t.date != todayKey) continue;
    if (t.type != rule.type) continue;
    if (t.amount != rule.amount) continue;
    if (t.currency != rule.currency) continue;
    if (t.categoryId != rule.categoryId) continue;
    return true;
  }
  return false;
}
