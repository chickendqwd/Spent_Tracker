import 'package:flutter_test/flutter_test.dart';

import 'package:spent_tracker/core/utils/icon_util.dart';
import 'package:spent_tracker/data/models/recurring_rule.dart';
import 'package:spent_tracker/state/recurring_rule_providers.dart';

void main() {
  group('ruleMatches · 月末夹取（v3.2 · B5）', () {
    RecurringRule monthly(int dayValue) => RecurringRule(
          type: 0,
          amount: 1000,
          frequency: RecurringFrequency.monthly.index,
          dayValue: dayValue,
          startDate: '2026-01-01',
        );

    test('每月 31 号：小月落到月末，不再整月不命中', () {
      final rule = monthly(31);
      expect(ruleMatches(rule, DateTime(2026, 4, 30)), isTrue, reason: '4 月 30 日是月末');
      expect(ruleMatches(rule, DateTime(2026, 4, 29)), isFalse);
      expect(ruleMatches(rule, DateTime(2026, 2, 28)), isTrue, reason: '平年 2 月月末');
      expect(ruleMatches(rule, DateTime(2024, 2, 29)), isTrue, reason: '闰年 2 月月末');
      expect(ruleMatches(rule, DateTime(2026, 1, 31)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 5, 31)), isTrue);
    });

    test('每月 29 号：平年 2 月落到 28 日', () {
      final rule = monthly(29);
      expect(ruleMatches(rule, DateTime(2026, 2, 28)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 2, 27)), isFalse);
      expect(ruleMatches(rule, DateTime(2024, 2, 29)), isTrue);
    });

    test('每月 15 号：不受夹取影响', () {
      final rule = monthly(15);
      expect(ruleMatches(rule, DateTime(2026, 2, 15)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 2, 16)), isFalse);
    });

    test('每月任一天：同一月份只命中一次', () {
      for (final day in [1, 15, 28, 29, 30, 31]) {
        final rule = monthly(day);
        final month = DateTime(2026, 2, 1);
        var hits = 0;
        for (var d = 1; d <= 28; d++) {
          if (ruleMatches(rule, DateTime(month.year, month.month, d))) hits++;
        }
        expect(hits, 1, reason: '2026 年 2 月，$day 号规则应恰好命中一次');
      }
    });

    test('每年 2/29：平年落到 2/28，月份不符不命中', () {
      final rule = RecurringRule(
        type: 0,
        amount: 1000,
        frequency: RecurringFrequency.yearly.index,
        dayValue: 29,
        startDate: '2024-02-29',
      );
      expect(ruleMatches(rule, DateTime(2026, 2, 28)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 3, 28)), isFalse);
      expect(ruleMatches(rule, DateTime(2024, 2, 29)), isTrue);
    });

    test('每周：按周几命中', () {
      final rule = RecurringRule(
        type: 0,
        amount: 1000,
        frequency: RecurringFrequency.weekly.index,
        dayValue: 4, // 周四
        startDate: '2026-01-01',
      );
      expect(ruleMatches(rule, DateTime(2026, 11, 19)), isTrue);
      expect(ruleMatches(rule, DateTime(2026, 11, 20)), isFalse);
    });
  });

  group('normalizeCategoryIcon（v3.2 · R1）', () {
    test('单个 emoji 合法', () {
      expect(normalizeCategoryIcon('🐹'), '🐹');
      expect(normalizeCategoryIcon('🍜'), '🍜');
      // 组合 emoji（ZWJ 序列）算作 1 个字符，不应被 String.length 误判
      expect(normalizeCategoryIcon('👨‍👩‍👧'), '👨‍👩‍👧');
    });

    test('1–2 个普通字符合法', () {
      expect(normalizeCategoryIcon('a'), 'a');
      expect(normalizeCategoryIcon('ab'), 'ab');
    });

    test('超过 2 个字符非法', () {
      expect(normalizeCategoryIcon('abc'), isNull);
      expect(normalizeCategoryIcon('🐹🐹🐹'), isNull);
    });

    test('空、纯空白、换行非法', () {
      expect(normalizeCategoryIcon(null), isNull);
      expect(normalizeCategoryIcon(''), isNull);
      expect(normalizeCategoryIcon('   '), isNull);
      expect(normalizeCategoryIcon('a\nb'), isNull);
    });

    test('首尾空白会被裁剪', () {
      expect(normalizeCategoryIcon(' 🐹 '), '🐹');
    });
  });
}
