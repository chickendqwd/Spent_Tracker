import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../utils/date_util.dart';

/// 趋势图区间（v3.2）：本周 / 本月 / 近 3 月 / 近 6 月 / 近 12 月。
///
/// 步长口径力求“每档大致 18–30 个点”，便于折线呈现日间波动，
/// 同时避免点数过多导致 X 轴标签重叠。
enum TrendRange {
  week('本周', 1),
  month('本月', 1),
  threeMonths('近3月', 5),
  sixMonths('近6月', 10),
  twelveMonths('近12月', 15);

  const TrendRange(this.label, this.stepDays);

  final String label;

  /// 相邻折线点的间隔天数（本周/本月为 1，即逐日）。
  final int stepDays;

  /// 平铺展示的常用档位，其余进「更多…」菜单。
  static const List<TrendRange> pinned = [
    TrendRange.week,
    TrendRange.month,
    TrendRange.threeMonths,
  ];

  static const List<TrendRange> overflow = [
    TrendRange.sixMonths,
    TrendRange.twelveMonths,
  ];
}

/// 一个区间内的收支桶（金额为基准币种分）。
///
/// `start`/`end` 均含端点；空桶金额为 0，不跳过，保证折线连续。
/// [inFuture] 为 true 表示该桶在 `today` 之后：X 轴照常占位，但不画数据点。
class TrendBucket {
  const TrendBucket({
    required this.start,
    required this.end,
    required this.expense,
    required this.income,
    this.inFuture = false,
  });

  final DateTime start;
  final DateTime end;
  final int expense;
  final int income;

  /// 该桶是否还没到（本周/本月会生成整段区间，未来天只占位不出数）
  final bool inFuture;

  /// X 轴短标签，如「11/3」。
  String get shortLabel => '${start.month}/${start.day}';

  /// 悬浮提示用完整区间标签，如「11/3–11/7」。
  String get rangeLabel => start == end
      ? shortLabel
      : '$shortLabel–${end.month}/${end.day}';
}

/// 某月收支点（金额为基准币种分），供年度报告复用。
///
/// 趋势图已改为按区间分桶（[TrendBucket]），此类型仅用于年报的 1–12 月柱状数据。
class MonthlyPoint {
  const MonthlyPoint({
    required this.month,
    required this.expense,
    required this.income,
  });

  /// yyyy-MM
  final String month;
  final int expense;
  final int income;
}

/// 把单笔账目折算为基准币种分的函数（由调用方注入，core 层不依赖 state）。
/// v3.4.1 起回调接收整笔账目，调用方可读取记账时的汇率快照。
typedef CentsConverter = int Function(Transaction transaction);

/// 生成某区间内按 [TrendRange.stepDays] 切分的桶区间（含端点，按天对齐）。
///
/// - 本周：周一 → 周日，固定 7 桶；本月：1 号 → 月末，整月天数。
///   这两档会把「还没到的天」也作为占位桶生成（见 [TrendBucket.inFuture]），
///   避免 X 轴只铺到今天就显得挤在一起。
/// - 近 3 / 6 / 12 月：区间终点固定为 `today`（含），不回看未来，避免出现"未来全是 0"的假下降。
List<({DateTime start, DateTime end})> trendBucketRanges(
  TrendRange range,
  DateTime today,
) {
  final t = DateTime(today.year, today.month, today.day);
  final DateTime from;
  final DateTime until;
  switch (range) {
    case TrendRange.week:
      // 本周一（weekday: 周一=1 … 周日=7）→ 本周日
      from = t.subtract(Duration(days: t.weekday - 1));
      until = DateTime(from.year, from.month, from.day + 6);
    case TrendRange.month:
      from = DateTime(t.year, t.month, 1);
      // 当月最后一天：下月 0 号
      until = DateTime(t.year, t.month + 1, 0);
    case TrendRange.threeMonths:
      from = t.subtract(const Duration(days: 89)); // 90 天 × 5 天步长 = 18 桶
      until = t;
    case TrendRange.sixMonths:
      from = t.subtract(const Duration(days: 179)); // 180 天 / 10 = 18 桶
      until = t;
    case TrendRange.twelveMonths:
      from = t.subtract(const Duration(days: 359)); // 360 天 / 15 = 24 桶
      until = t;
  }

  final ranges = <({DateTime start, DateTime end})>[];
  var cursor = DateTime(from.year, from.month, from.day);
  while (!cursor.isAfter(until)) {
    final end = cursor.add(Duration(days: range.stepDays - 1));
    ranges.add((
      start: cursor,
      end: end.isAfter(until) ? until : end,
    ));
    cursor = cursor.add(Duration(days: range.stepDays));
  }
  return ranges;
}

/// 按桶聚合账目：先按天落到桶索引，再累加，整体 O(桶天数 + 账目数)。
///
/// [toCents] 把单笔账目折成基准币种分；空区间桶保留 0 值。
/// [today] 用于标记未来桶：起点晚于今天的桶 `inFuture = true`，UI 不应为它画数据点。
List<TrendBucket> computeTrendBuckets({
  required List<({DateTime start, DateTime end})> ranges,
  required List<Transaction> transactions,
  required CentsConverter toCents,
  required DateTime today,
}) {
  final t = DateTime(today.year, today.month, today.day);
  final indexByDay = <String, int>{};
  for (var i = 0; i < ranges.length; i++) {
    final r = ranges[i];
    var cursor = DateTime(r.start.year, r.start.month, r.start.day);
    while (!cursor.isAfter(r.end)) {
      indexByDay[DateUtil.toDayKey(cursor)] = i;
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
  }

  final expense = List<int>.filled(ranges.length, 0);
  final income = List<int>.filled(ranges.length, 0);

  for (final tr in transactions) {
    final idx = indexByDay[tr.date];
    if (idx == null) continue;
    final cents = toCents(tr);
    if (tr.transactionType == TransactionType.expense) {
      expense[idx] += cents;
    } else {
      income[idx] += cents;
    }
  }

  return [
    for (var i = 0; i < ranges.length; i++)
      TrendBucket(
        start: ranges[i].start,
        end: ranges[i].end,
        expense: expense[i],
        income: income[i],
        inFuture: ranges[i].start.isAfter(t),
      ),
  ];
}
