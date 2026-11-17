import '../models/recurring_rule.dart';
import 'database.dart';

/// 周期记账规则仓库（v2）。
class RecurringRuleRepository {
  const RecurringRuleRepository();

  /// 全部规则（按创建顺序）。
  List<RecurringRule> getAll() => Db.recurringRules.values.toList();

  /// 启用中的规则。
  List<RecurringRule> getActive() =>
      Db.recurringRules.values.where((r) => r.active).toList();

  Future<int> add(RecurringRule rule) => Db.recurringRules.add(rule);

  Future<void> update(RecurringRule rule) => rule.save();

  Future<void> delete(int key) => Db.recurringRules.delete(key);
}
