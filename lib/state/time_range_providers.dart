import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_util.dart';

/// 时间筛选区间类型（v2）。
enum TimeRangeKind {
  thisWeek('本周'),
  thisMonth('本月'),
  lastMonth('上月'),
  last7Days('近7天'),
  custom('自定义');

  const TimeRangeKind(this.label);
  final String label;
}

/// 时间筛选：kind + 自定义区间（仅 custom 使用）。
class TimeRange {
  const TimeRange(this.kind, {this.customStart, this.customEnd})
      : assert(kind != TimeRangeKind.custom || (customStart != null && customEnd != null));

  final TimeRangeKind kind;
  final DateTime? customStart;
  final DateTime? customEnd;
}

/// 计算出的实际日期区间（含端点），供各处聚合过滤。
class DateRange {
  const DateRange({required this.start, required this.end, required this.startKey, required this.endKey});

  final DateTime start;
  final DateTime end;

  /// yyyy-MM-dd，用于与账目 date 字符串比较。
  final String startKey;
  final String endKey;

  bool contains(DateTime date) =>
      !date.isBefore(start) && !date.isAfter(end);

  bool containsKey(String dayKey) =>
      dayKey.compareTo(startKey) >= 0 && dayKey.compareTo(endKey) <= 0;
}

/// 时间筛选状态：默认「本月」（与 v1 行为一致）。
class TimeRangeNotifier extends Notifier<TimeRange> {
  @override
  TimeRange build() => const TimeRange(TimeRangeKind.thisMonth);

  void set(TimeRange range) => state = range;

  void setKind(TimeRangeKind kind) {
    state = TimeRange(kind);
  }
}

final timeRangeProvider = NotifierProvider<TimeRangeNotifier, TimeRange>(
  TimeRangeNotifier.new,
);

/// 由所选区间计算实际 [start, end]。
final dateRangeProvider = Provider<DateRange>((ref) {
  final range = ref.watch(timeRangeProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (range.kind) {
    case TimeRangeKind.thisWeek:
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return DateRange(
        start: monday,
        end: sunday,
        startKey: DateUtil.toDayKey(monday),
        endKey: DateUtil.toDayKey(sunday),
      );
    case TimeRangeKind.thisMonth:
      final start = DateTime(today.year, today.month, 1);
      final end = DateTime(today.year, today.month + 1, 0);
      return DateRange(
        start: start,
        end: end,
        startKey: DateUtil.toDayKey(start),
        endKey: DateUtil.toDayKey(end),
      );
    case TimeRangeKind.lastMonth:
      final start = DateTime(today.year, today.month - 1, 1);
      final end = DateTime(today.year, today.month, 0);
      return DateRange(
        start: start,
        end: end,
        startKey: DateUtil.toDayKey(start),
        endKey: DateUtil.toDayKey(end),
      );
    case TimeRangeKind.last7Days:
      final start = today.subtract(const Duration(days: 6));
      return DateRange(
        start: start,
        end: today,
        startKey: DateUtil.toDayKey(start),
        endKey: DateUtil.toDayKey(today),
      );
    case TimeRangeKind.custom:
      return DateRange(
        start: range.customStart!,
        end: range.customEnd!,
        startKey: DateUtil.toDayKey(range.customStart!),
        endKey: DateUtil.toDayKey(range.customEnd!),
      );
  }
});
