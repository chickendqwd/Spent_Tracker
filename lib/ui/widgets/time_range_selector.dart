import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/time_range_providers.dart';

/// 时间范围切换器（v2）：本周 / 本月 / 上月 / 近7天 + 自定义区间。
/// 总览页与交易列表页共用，切换后全局联动（timeRangeProvider）。
class TimeRangeSelector extends ConsumerWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = ref.watch(timeRangeProvider);
    final isCustom = range.kind == TimeRangeKind.custom;

    return Row(
      children: [
        Expanded(
          child: SegmentedButton<TimeRangeKind>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              ButtonSegment(
                value: TimeRangeKind.thisWeek,
                label: Text(l10n.timeRange(TimeRangeKind.thisWeek)),
              ),
              ButtonSegment(
                value: TimeRangeKind.thisMonth,
                label: Text(l10n.timeRange(TimeRangeKind.thisMonth)),
              ),
              ButtonSegment(
                value: TimeRangeKind.lastMonth,
                label: Text(l10n.timeRange(TimeRangeKind.lastMonth)),
              ),
              ButtonSegment(
                value: TimeRangeKind.last7Days,
                label: Text(l10n.timeRange(TimeRangeKind.last7Days)),
              ),
            ],
            // 自定义区间时不高亮任一常用项
            selected: isCustom ? <TimeRangeKind>{} : {range.kind},
            onSelectionChanged: (s) =>
                ref.read(timeRangeProvider.notifier).setKind(s.first),
          ),
        ),
        const SizedBox(width: 8),
        // 自定义区间：图标按钮 + 当前选中标签（仅自定义时显示）
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.date_range_outlined, size: 18),
          label: Text(
            isCustom
                ? '${_short(range.customStart!.month)}/${_short(range.customStart!.day)}-${_short(range.customEnd!.month)}/${_short(range.customEnd!.day)}'
                : l10n.timeRange(TimeRangeKind.custom),
            style: const TextStyle(fontSize: 12),
          ),
          onPressed: () async {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: today,
              initialDateRange: isCustom
                  ? DateTimeRange(
                      start: range.customStart!,
                      end: range.customEnd!,
                    )
                  : null,
            );
            if (picked != null) {
              ref.read(timeRangeProvider.notifier).set(
                    TimeRange(
                      TimeRangeKind.custom,
                      customStart: picked.start,
                      customEnd: picked.end,
                    ),
                  );
            }
          },
        ),
      ],
    );
  }

  String _short(int v) => v.toString();
}
