import 'package:flutter_test/flutter_test.dart';

import 'package:spent_tracker/core/analytics/trend_analytics.dart';
import 'package:spent_tracker/data/models/transaction.dart';

void main() {
  // 固定“今天”为 2026-11-19（周四），避免跨天/跨月导致断言漂移。
  final today = DateTime(2026, 11, 19);

  group('trendBucketRanges', () {
    test('本周：周一到周日固定 7 个桶，还没到的天也占位', () {
      final ranges = trendBucketRanges(TrendRange.week, today);
      expect(ranges.length, 7); // 周一 16 日 … 周日 22 日
      expect(ranges.first.start, DateTime(2026, 11, 16));
      expect(ranges.last.end, DateTime(2026, 11, 22));
    });

    test('本月：从 1 号到月末，整月天数', () {
      final ranges = trendBucketRanges(TrendRange.month, today);
      expect(ranges.first.start, DateTime(2026, 11, 1));
      expect(ranges.length, 30); // 2026 年 11 月 30 天
      expect(ranges.last.end, DateTime(2026, 11, 30));
    });

    test('近 3/6/12 月：按 5/10/15 天分桶，点数约 18/18/24', () {
      final three = trendBucketRanges(TrendRange.threeMonths, today);
      final six = trendBucketRanges(TrendRange.sixMonths, today);
      final twelve = trendBucketRanges(TrendRange.twelveMonths, today);

      expect(three.length, 18);
      expect(six.length, 18);
      expect(twelve.length, 24);

      // 每档最后一个桶不得越过今天
      for (final ranges in [three, six, twelve]) {
        expect(ranges.last.end, today);
        expect(ranges.last.end.isAfter(today), isFalse);
      }
    });

    test('桶区间连续、无重叠、无空洞', () {
      final ranges = trendBucketRanges(TrendRange.threeMonths, today);
      for (var i = 1; i < ranges.length; i++) {
        final prevEnd = ranges[i - 1].end;
        final nextStart = ranges[i].start;
        expect(
          nextStart.difference(prevEnd).inDays,
          1,
          reason: '第 $i 个桶的起点应紧接上一个桶的终点',
        );
      }
    });
  });

  group('computeTrendBuckets', () {
    // 恒等折算，专注验证分桶逻辑
    int identity(Transaction t) => t.amount;

    Transaction tx(String date, int amount, {int type = 0}) => Transaction(
          type: type,
          amount: amount,
          date: date,
          createdAt: DateTime(2026, 11, 19),
        );

    test('账目落到正确桶，空桶保留 0', () {
      final ranges = trendBucketRanges(TrendRange.week, today);
      final buckets = computeTrendBuckets(
        ranges: ranges,
        transactions: [
          tx('2026-11-16', 1200), // 周一
          tx('2026-11-16', 300), // 周一（累加）
          tx('2026-11-18', 500, type: 1), // 周三收入
          tx('2026-11-10', 9999), // 区间外，应被忽略
        ],
        toCents: identity,
        today: today,
      );

      expect(buckets[0].expense, 1500);
      expect(buckets[0].income, 0);
      expect(buckets[1].expense, 0); // 周二空桶
      expect(buckets[2].income, 500);
      expect(buckets[3].expense, 0);
      // 区间外记录不污染任何桶
      expect(buckets.fold<int>(0, (sum, b) => sum + b.expense), 1500);
    });

    test('跨月区间：上月末的账目落在第一个桶', () {
      final ranges = trendBucketRanges(TrendRange.threeMonths, today);
      final buckets = computeTrendBuckets(
        ranges: ranges,
        transactions: [tx('2026-08-22', 800)],
        toCents: identity,
        today: today,
      );
      expect(buckets.first.expense, 800);
    });

    test('折算函数按币种被调用（金额按基准币种分入桶）', () {
      final ranges = trendBucketRanges(TrendRange.week, today);
      // 模拟“1 单位 CNY = 0.19 SGD 分”的折算
      int convert(Transaction t) =>
          t.currency == 'SGD' ? t.amount : (t.amount * 0.19).round();
      final buckets = computeTrendBuckets(
        ranges: ranges,
        transactions: [
          tx('2026-11-19', 1000, type: 0),
          Transaction(
            type: 0,
            amount: 1000,
            date: '2026-11-19',
            currency: 'CNY',
            createdAt: DateTime(2026, 11, 19),
          ),
        ],
        toCents: convert,
        today: today,
      );
      // 今天是周四 → 索引 3；后面三个是未来占位桶
      expect(buckets[3].expense, 1190);
      expect(buckets.where((b) => b.inFuture).length, 3);
    });

    test('未来桶标记 inFuture：今天之后的天占位，UI 不为其画点', () {
      final ranges = trendBucketRanges(TrendRange.week, today);
      final buckets = computeTrendBuckets(
        ranges: ranges,
        transactions: [tx('2026-11-20', 777)], // 周五（还没到）
        toCents: identity,
        today: today,
      );

      // 周一…周四已到达，周五/六/日三个桶在未来
      expect(buckets.length, 7);
      expect(buckets.firstWhere((b) => b.inFuture).start, DateTime(2026, 11, 20));
      expect(buckets.last.start, DateTime(2026, 11, 22));
      // 落在未来日期的账目仍聚合进对应桶（列表可记未来账），只是曲线不画到那里
      expect(buckets[4].expense, 777);
      expect(buckets[4].inFuture, isTrue);
    });
  });
}
