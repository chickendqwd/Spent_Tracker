import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/trend_analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction.dart';
import '../../l10n/l10n.dart';
import '../../state/budget_providers.dart';
import '../../state/category_providers.dart';
import '../../state/currency_providers.dart';
import '../../state/recurring_rule_providers.dart';
import '../../state/summary_providers.dart';
import '../../state/trend_providers.dart';
import '../analysis/annual_page.dart';
import '../transactions/transaction_list_page.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';

/// 总览页（v2）：
/// 时间范围切换 → 今日待记提示条 → 总账三卡片 → 本月预算进度条
/// → 收支趋势折线图 → 分类分析（环形图+排行） → 最近记录。
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(rangeSummaryProvider);
    final recent = ref.watch(rangeRecentTransactionsProvider);
    final categories = ref.watch(categoryProvider);
    final categoryByKey = {for (final c in categories) c.key as int: c};
    final totalBudget = ref.watch(totalBudgetProvider);
    final thisMonthExpense = ref.watch(thisMonthExpenseProvider);
    final dueRules = ref.watch(todayDueRulesProvider);
    final currencies = ref.watch(currencyProvider);
    final baseSymbol = ref.watch(baseCurrencyProvider).symbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.overviewTitle),
        actions: [
          IconButton(
            tooltip: l10n.overviewAnnualTooltip,
            icon: const Icon(Icons.calendar_view_month_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnualPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const TimeRangeSelector(),
          if (dueRules.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TodayDueBanner(rules: dueRules),
          ],
          const SizedBox(height: 12),
          // 总账三卡片（所选区间，基准币种）
          Row(
            children: [
              _StatCard(
                label: l10n.overviewTotalExpense,
                amount: summary.totalExpense,
                color: context.palette.expense,
                symbol: baseSymbol,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: l10n.overviewTotalIncome,
                amount: summary.totalIncome,
                color: context.palette.income,
                symbol: baseSymbol,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: l10n.overviewBalance,
                amount: summary.balance,
                color: Theme.of(context).colorScheme.onSurface,
                symbol: baseSymbol,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (totalBudget != null) ...[
            _BudgetCard(
              // 预算存的是 SGD 分，展示与已用金额统一换算到当前基准币种
              budgetAmount: budgetCentsInBase(currencies, totalBudget.amount),
              used: thisMonthExpense,
              symbol: baseSymbol,
            ),
            const SizedBox(height: 16),
          ],
          _TrendCard(symbol: baseSymbol),
          const SizedBox(height: 16),
          _CategoryAnalysisCard(summary: summary, symbol: baseSymbol),
          const SizedBox(height: 16),
          // 最近记录（所选区间）
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.overviewRecent,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionListPage(),
                          ),
                        ),
                        child: Text(l10n.overviewViewAll),
                      ),
                    ],
                  ),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text(l10n.overviewRecentEmpty)),
                    )
                  else
                    for (final t in recent)
                      TransactionTile(
                        transaction: t,
                        category: t.categoryId == null
                            ? null
                            : categoryByKey[t.categoryId],
                        onTap: () => TransactionDetailSheet.show(context, t),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 今日待记提示条：点击进入预填录入面板（手动确认入账）。
class _TodayDueBanner extends StatelessWidget {
  const _TodayDueBanner({required this.rules});

  final List<RecurringRule> rules;

  @override
  Widget build(BuildContext context) {
    final first = rules.first;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => AddTransactionSheet.show(
          context,
          prefill: Transaction(
            type: first.type,
            amount: first.amount,
            categoryId: first.categoryId,
            date: DateUtil.toDayKey(DateTime.now()),
            note: first.note,
            currency: first.currency,
            createdAt: DateTime.now(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.event_available, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.overviewTodayDue('${rules.length}'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.symbol,
  });

  final String label;
  final int amount;
  final Color color;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(color: context.palette.muted),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  MoneyUtil.format(amount, symbol: symbol),
                  style: textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 本月预算进度条：已用 / 总额；超支标红。
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budgetAmount,
    required this.used,
    required this.symbol,
  });

  final int budgetAmount;
  final int used;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final over = used > budgetAmount;
    final progress = budgetAmount <= 0 ? 0.0 : (used / budgetAmount).clamp(0.0, 1.0);
    final color = over ? context.palette.expense : Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.overviewMonthlyBudget,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${MoneyUtil.format(used, symbol: symbol)} / ${MoneyUtil.format(budgetAmount, symbol: symbol)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: color,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            if (over) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.overviewOverBudget,
                style: TextStyle(color: context.palette.expense, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 收支趋势折线图（v3.2）：区间可切（本周/本月/近3月/近6月/近12月），
/// 按区间步长降采样，呈现日间波动；双线（支出、收入）。
class _TrendCard extends ConsumerWidget {
  const _TrendCard({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trend = ref.watch(trendProvider);
    final range = ref.watch(trendRangeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.overviewTrendTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _TrendRangePicker(
              current: range,
              onChanged: (r) => ref.read(trendRangeProvider.notifier).set(r),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (trend.length - 1).toDouble(),
                  minY: 0,
                  maxY: _maxY(trend) * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _niceInterval(trend),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: _niceInterval(trend),
                        getTitlesWidget: (v, meta) => Text(
                          (v / 100).toStringAsFixed(0),
                          style: TextStyle(fontSize: 10, color: context.palette.muted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        // 周视图两行标签（日期 + 单字星期），需要更多高度
                        reservedSize: range == TrendRange.week ? 38 : 28,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if (i < 0 || i >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          final isWeek = range == TrendRange.week;
                          // 周视图每天都带标签；其余档位点数多，抽样显示避免重叠
                          final every = isWeek ? 1 : (trend.length / 6).ceil();
                          if (i % every != 0 && i != trend.length - 1) {
                            return const SizedBox.shrink();
                          }
                          if (isWeek) {
                            // 日期在上、星期在下（周一→「一」…周日→「日」）
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trend[i].shortLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.palette.muted,
                                  ),
                                ),
                                Text(
                                  l10n.weekdayChar(trend[i].start.weekday),
                                  style: TextStyle(
                                    fontSize: 9,
                                    height: 1.1,
                                    color: context.palette.muted,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Text(
                            trend[i].shortLabel,
                            style: TextStyle(fontSize: 10, color: context.palette.muted),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            _tooltipText(l10n, s, trend),
                            TextStyle(color: context.palette.onChartLabel),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    _line(
                      trend,
                      (b) => b.expense,
                      context.palette.expense,
                    ),
                    _line(
                      trend,
                      (b) => b.income,
                      context.palette.income,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _legendDot(l10n.typeExpense, context.palette.expense),
            _legendDot(l10n.typeIncome, context.palette.income),
          ],
        ),
      ),
    );
  }

  /// 悬浮提示：类型 + 区间 + 金额。
  String _tooltipText(
    AppLocalizations l10n,
    LineBarSpot spot,
    List<TrendBucket> trend,
  ) {
    final i = spot.x.round();
    if (i < 0 || i >= trend.length) return '';
    final b = trend[i];
    final label = spot.barIndex == 0 ? l10n.typeExpense : l10n.typeIncome;
    return '$label ${b.rangeLabel}\n${MoneyUtil.format(spot.y.round(), symbol: symbol)}';
  }

  Widget _legendDot(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// 折线只画到「今天」：本周/本月 X 轴后续是未来占位桶，不连线也不画点，
  /// 因此周五打开时曲线停在周五，但轴上仍能看见六、日的位置。
  LineChartBarData _line(
    List<TrendBucket> trend,
    int Function(TrendBucket) value,
    Color color,
  ) {
    // 最后一个「已到达」的桶；全部在未来时退回 0，避免空 spots
    var last = trend.lastIndexWhere((b) => !b.inFuture);
    if (last < 0) last = 0;
    return LineChartBarData(
      spots: [
        for (var i = 0; i <= last; i++)
          FlSpot(i.toDouble(), value(trend[i]).toDouble()),
      ],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
          radius: spot.x == last ? 3.5 : 2,
          color: color,
          strokeWidth: 0,
        ),
      ),
    );
  }

  double _maxY(List<TrendBucket> trend) {
    var m = 0.0;
    for (final p in trend) {
      m = m > p.expense ? m : p.expense.toDouble();
      m = m > p.income ? m : p.income.toDouble();
    }
    return m;
  }

  double _niceInterval(List<TrendBucket> trend) {
    final maxY = _maxY(trend);
    if (maxY <= 0) return 1000;
    // 取 1/2/5×10^n 步长，使 Y 轴刻度友好
    final raw = maxY / 4;
    final exp = (raw <= 0) ? 0.0 : (math.log(raw) / math.ln10).floorToDouble();
    final base = _pow10(exp);
    final firstDigit = raw / base;
    final factor = firstDigit <= 1 ? 1.0 : (firstDigit <= 2 ? 2.0 : (firstDigit <= 5 ? 5.0 : 10.0));
    return base * factor;
  }

  double _pow10(double e) {
    var r = 1.0;
    for (var i = 0; i < e; i++) {
      r *= 10;
    }
    for (var i = 0; i > e; i--) {
      r /= 10;
    }
    return r;
  }
}

/// 趋势区间选择：本周 / 本月 / 近 3 月平铺，近 6 月 / 近 12 月收进「更多…」菜单。
class _TrendRangePicker extends StatelessWidget {
  const _TrendRangePicker({required this.current, required this.onChanged});

  final TrendRange current;
  final ValueChanged<TrendRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overflowSelected = TrendRange.overflow.contains(current);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final r in TrendRange.pinned)
          ChoiceChip(
            label: Text(l10n.trendRange(r)),
            selected: current == r,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onChanged(r),
          ),
        if (overflowSelected)
          // 选中长区间时把当前档位显示出来，避免「没有选中项」的错觉
          ChoiceChip(
            label: Text(l10n.trendRange(current)),
            selected: true,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onChanged(current),
          ),
        // 「更多…」入口常驻：默认选中近 6 月时也要能切到近 12 月
        PopupMenuButton<TrendRange>(
          tooltip: l10n.trendMoreRanges,
          onSelected: onChanged,
          itemBuilder: (_) => [
            for (final r in TrendRange.overflow)
              PopupMenuItem(value: r, child: Text(l10n.trendRange(r))),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.commonMore,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.muted,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 16,
                  color: context.palette.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 分类分析：支出 / 收入 Tab，环形图占比 + 金额排行。
class _CategoryAnalysisCard extends ConsumerStatefulWidget {
  const _CategoryAnalysisCard({required this.summary, required this.symbol});

  final RangeSummary summary;
  final String symbol;

  @override
  ConsumerState<_CategoryAnalysisCard> createState() =>
      _CategoryAnalysisCardState();
}

class _CategoryAnalysisCardState extends ConsumerState<_CategoryAnalysisCard> {
  int _tab = 0; // 0=支出，1=收入

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final shares = _tab == 0
        ? widget.summary.expenseByCategory
        : widget.summary.incomeByCategory;
    final total = _tab == 0
        ? widget.summary.totalExpense
        : widget.summary.totalIncome;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.overviewCategoryAnalysis,
                    style: textTheme.titleMedium),
                const Spacer(),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: [
                    ButtonSegment(value: 0, label: Text(l10n.typeExpense)),
                    ButtonSegment(value: 1, label: Text(l10n.typeIncome)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    _tab == 0
                        ? l10n.overviewNoExpenseInRange
                        : l10n.overviewNoIncomeInRange,
                  ),
                ),
              )
            else
              SizedBox(
                height: 210,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                          sections: [
                            for (final (i, share) in shares.indexed)
                              PieChartSectionData(
                                value: share.amountCents.toDouble(),
                                color: context.palette.chartPalette[
                                    i % context.palette.chartPalette.length],
                                radius: 50,
                                title:
                                    '${(share.amountCents / total * 100).toStringAsFixed(0)}%',
                                titleStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.palette.onChartLabel,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (i, share) in shares.indexed)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: context.palette.chartPalette[
                                          i % context.palette.chartPalette.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      categoryDisplayName(l10n, share.category),
                                      style: textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    MoneyUtil.format(
                                      share.amountCents,
                                      symbol: widget.symbol,
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
