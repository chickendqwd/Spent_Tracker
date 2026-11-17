import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/utils/date_util.dart';
import '../data/db/database.dart';
import '../data/db/recurring_rule_repository.dart';
import '../data/models/recurring_rule.dart';

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
bool ruleMatches(RecurringRule rule, DateTime day) {
  switch (rule.recurringFrequency) {
    case RecurringFrequency.weekly:
      return day.weekday == rule.dayValue;
    case RecurringFrequency.monthly:
      return day.day == rule.dayValue;
    case RecurringFrequency.yearly:
      return day.month == DateUtil.fromDayKey(rule.startDate).month &&
          day.day == rule.dayValue;
  }
}

/// 今天到期的启用规则（用于总览「今日待记」提示条）。
final todayDueRulesProvider = Provider<List<RecurringRule>>((ref) {
  final rules = ref.watch(recurringRuleProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return rules
      .where(
        (r) =>
            r.active &&
            !today.isBefore(DateUtil.fromDayKey(r.startDate)) &&
            ruleMatches(r, today),
      )
      .toList();
});
