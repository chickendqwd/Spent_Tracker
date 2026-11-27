import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../state/time_range_providers.dart';
import 'surfaces.dart';

/// 时间范围切换器：本周 / 本月 / 上月 / 近7天 + 自定义区间。
/// 总览页与交易列表页共用，切换后全局联动（timeRangeProvider）。
class TimeRangeSelector extends ConsumerWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final range = ref.watch(timeRangeProvider);
    final resolved = ref.watch(dateRangeProvider);
    final isCustom = range.kind == TimeRangeKind.custom;

    const kinds = <TimeRangeKind>[
      TimeRangeKind.thisWeek,
      TimeRangeKind.thisMonth,
      TimeRangeKind.lastMonth,
      TimeRangeKind.last7Days,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final kind in kinds)
          PillChip(
            label: l10n.timeRange(kind),
            // 自定义区间时不高亮任一常用项
            selected: !isCustom && range.kind == kind,
            onTap: () => ref.read(timeRangeProvider.notifier).setKind(kind),
          ),
        // 自定义区间：图标按钮 + 当前选中标签（仅自定义时显示范围）
        PillChip(
          label: isCustom
              ? '${_short(range.customStart!.month)}/${_short(range.customStart!.day)}-${_short(range.customEnd!.month)}/${_short(range.customEnd!.day)}'
              : l10n.timeRange(TimeRangeKind.custom),
          icon: Icons.date_range_outlined,
          selected: isCustom,
          onTap: () async {
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
        if (!isCustom)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              _summary(resolved),
              style: TextStyle(fontSize: 11.5, color: palette.muted),
            ),
          ),
      ],
    );
  }

  /// 当前区间的日期范围摘要（如 11/24-11/30），帮助确认筛了哪几天。
  String _summary(DateRange range) {
    final start = range.start;
    final end = range.end;
    return '${start.month}/${start.day}-${end.month}/${end.day}';
  }

  String _short(int v) => v.toString();
}
