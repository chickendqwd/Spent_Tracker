import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/data/db/budget_repository.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/db/recurring_rule_repository.dart';
import 'package:spent_tracker/data/models/budget.dart';
import 'package:spent_tracker/data/models/currency.dart';
import 'package:spent_tracker/data/models/recurring_rule.dart';
import 'package:spent_tracker/state/currency_providers.dart';
import 'package:spent_tracker/state/recurring_rule_providers.dart';
import 'package:spent_tracker/state/time_range_providers.dart';

/// v2 新功能（预算、时间筛选、周期记账、多货币）数据/逻辑层测试。
/// 沿用 v1 仓库单测模式：真实异步环境验证规则。
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_tracker_v2_test');
    await initDatabaseAt(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('预算：effectiveForMonth', () {
    test('当月未设置时沿用最近一个设有预算的月份', () async {
      // 无预算 → 空
      expect(const BudgetRepository().effectiveForMonth('2026-11'), isEmpty);

      // 设置 2026-09 与 2026-10
      await const BudgetRepository().add(
        Budget(type: BudgetType.total.index, month: '2026-09', amount: 10000),
      );
      await const BudgetRepository().add(
        Budget(type: BudgetType.total.index, month: '2026-10', amount: 20000),
      );

      // 当月命中
      final oct = const BudgetRepository().effectiveForMonth('2026-10');
      expect(oct.single.amount, 20000);
      // 2026-11 未设置 → 沿用最近 2026-10
      final nov = const BudgetRepository().effectiveForMonth('2026-11');
      expect(nov.single.amount, 20000);
      // 2026-09 命中自身
      expect(const BudgetRepository().effectiveForMonth('2026-09').single.amount,
          10000);
      // 更早月份从未设置 → 空
      expect(const BudgetRepository().effectiveForMonth('2026-08'), isEmpty);
    });
  });

  group('时间筛选：DateRange 区间判定', () {
    test('本月区间包含月初/月末，不含上月', () {
      final today = DateTime(2026, 10, 21);
      final start = DateTime(today.year, today.month, 1);
      final end = DateTime(today.year, today.month + 1, 0);
      final range = DateRange(
        start: start,
        end: end,
        startKey: '2026-10-01',
        endKey: '2026-10-31',
      );

      expect(range.containsKey('2026-10-01'), isTrue);
      expect(range.containsKey('2026-10-31'), isTrue);
      expect(range.containsKey('2026-10-15'), isTrue);
      expect(range.containsKey('2026-09-30'), isFalse);
      expect(range.containsKey('2026-11-01'), isFalse);
      expect(range.containsKey('2027-01-01'), isFalse);
    });

    test('自定义区间为闭区间，端点在范围内', () {
      final range = DateRange(
        start: DateTime(2026, 10, 5),
        end: DateTime(2026, 10, 20),
        startKey: '2026-10-05',
        endKey: '2026-10-20',
      );
      expect(range.containsKey('2026-10-05'), isTrue);
      expect(range.containsKey('2026-10-20'), isTrue);
      expect(range.containsKey('2026-10-04'), isFalse);
      expect(range.containsKey('2026-10-21'), isFalse);
    });
  });

  group('周期记账：ruleMatches 与 getActive', () {
    test('weekly 按周几匹配', () {
      final wednesday = DateTime(2026, 10, 21); // 周三
      final rule = RecurringRule(
        type: 0,
        amount: 500,
        frequency: RecurringFrequency.weekly.index,
        dayValue: wednesday.weekday, // 3
        startDate: '2026-10-01',
      );
      expect(ruleMatches(rule, wednesday), isTrue);
      expect(ruleMatches(rule, wednesday.add(const Duration(days: 1))), isFalse);
    });

    test('monthly 按几号匹配', () {
      final rule = RecurringRule(
        type: 0,
        amount: 500,
        frequency: RecurringFrequency.monthly.index,
        dayValue: 15,
        startDate: '2026-10-01',
      );
      expect(ruleMatches(rule, DateTime(2026, 10, 15)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 11, 15)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 10, 16)), isFalse);
    });

    test('yearly 在 startDate 所在月份按几号匹配', () {
      final rule = RecurringRule(
        type: 0,
        amount: 500,
        frequency: RecurringFrequency.yearly.index,
        dayValue: 5,
        startDate: '2026-10-05',
      );
      expect(ruleMatches(rule, DateTime(2027, 10, 5)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 10, 5)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 11, 5)), isFalse);
      expect(ruleMatches(rule, DateTime(2026, 10, 6)), isFalse);
    });

    test('getActive 只返回启用规则', () async {
      final repo = const RecurringRuleRepository();
      final k1 = await repo.add(
        RecurringRule(
          type: 0,
          amount: 500,
          frequency: RecurringFrequency.weekly.index,
          dayValue: 1,
          startDate: '2026-10-01',
          active: true,
        ),
      );
      final k2 = await repo.add(
        RecurringRule(
          type: 0,
          amount: 800,
          frequency: RecurringFrequency.monthly.index,
          dayValue: 10,
          startDate: '2026-10-01',
          active: false,
        ),
      );

      final active = repo.getActive();
      expect(active.map((r) => r.key), [k1]);
      expect(active.map((r) => r.key), isNot(contains(k2)));

      // 停用后不再出现
      final rule = repo.getAll().firstWhere((r) => r.key == k2);
      rule.active = true;
      await repo.update(rule);
      expect(repo.getActive().map((r) => r.key), contains(k2));
    });
  });

  group('多货币：toBaseCents 换算', () {
    test('非基准币种按汇率换算为 SGD 分', () {
      final currencies = [
        Currency(
          code: 'SGD',
          name: '新加坡元',
          symbol: 'S\$',
          rateToSgd: 1.0,
          isBase: true,
        ),
        Currency(
          code: 'CNY',
          name: '人民币',
          symbol: '¥',
          rateToSgd: 0.186,
        ),
      ];
      // 100 元 = 10000 分 → ×0.186 = 1860 分（SGD）
      expect(toBaseCents(currencies, 10000, 'CNY'), 1860);
      // 基准币种原样
      expect(toBaseCents(currencies, 5000, 'SGD'), 5000);
      // 币种缺失按 1 处理
      expect(toBaseCents(currencies, 5000, 'XYZ'), 5000);
    });
  });
}
