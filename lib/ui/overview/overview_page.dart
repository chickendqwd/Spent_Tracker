import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction.dart';
import '../../state/budget_providers.dart';
import '../../state/category_providers.dart';
import '../../state/currency_providers.dart';
import '../../state/recurring_rule_providers.dart';
import '../../state/summary_providers.dart';
import '../../state/trend_providers.dart';
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
    final summary = ref.watch(rangeSummaryProvider);
    final recent = ref.watch(rangeRecentTransactionsProvider);
    final categories = ref.watch(categoryProvider);
    final categoryByKey = {for (final c in categories) c.key as int: c};
    final totalBudget = ref.watch(totalBudgetProvider);
    final thisMonthExpense = ref.watch(thisMonthExpenseProvider);
    final dueRules = ref.watch(todayDueRulesProvider);
    final baseSymbol = ref.watch(baseCurrencyProvider).symbol;

    return Scaffold(
      appBar: AppBar(title: const Text('总览')),
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
                label: '总支出',
                amount: summary.totalExpense,
                color: context.palette.expense,
                symbol: baseSymbol,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: '总收入',
                amount: summary.totalIncome,
                color: context.palette.income,
                symbol: baseSymbol,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: '结余',
                amount: summary.balance,
                color: Theme.of(context).colorScheme.onSurface,
                symbol: baseSymbol,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (totalBudget != null) ...[
            _BudgetCard(
              budgetAmount: totalBudget.amount,
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
                  Text(
                    '最近记录',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('区间内还没有记录，点右下角「+」记一笔吧')),
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
                  '今日待记 ${rules.length} 笔，点按预填录入',
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
                Text('本月预算', style: Theme.of(context).textTheme.titleMedium),
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
                '已超出预算',
                style: TextStyle(color: context.palette.expense, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 收支趋势折线图：近 6 / 12 个月，双线（支出、收入）。
class _TrendCard extends ConsumerWidget {
  const _TrendCard({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(trendProvider);
    final count = ref.watch(trendMonthCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('收支趋势', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(value: 6, label: Text('近6月')),
                    ButtonSegment(value: 12, label: Text('近12月')),
                  ],
                  selected: {count},
                  onSelectionChanged: (s) => ref
                      .read(trendMonthCountProvider.notifier)
                      .set(s.first),
                ),
              ],
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
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                          final m = trend[i].month;
                          return Text(
                            '${int.parse(m.substring(5))}月',
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
                            '${s.y / 100} $symbol',
                            TextStyle(color: context.palette.onChartLabel),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    _line(
                      trend.map((p) => p.expense).toList(),
                      context.palette.expense,
                    ),
                    _line(
                      trend.map((p) => p.income).toList(),
                      context.palette.income,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _legendDot('支出', context.palette.expense),
            _legendDot('收入', context.palette.income),
          ],
        ),
      ),
    );
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

  LineChartBarData _line(List<int> values, Color color) {
    final maxI = values.length - 1;
    return LineChartBarData(
      spots: [
        for (final (i, v) in values.indexed) FlSpot(i.toDouble(), v.toDouble()),
      ],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
          radius: spot.x == maxI ? 3.5 : 2,
          color: color,
          strokeWidth: 0,
        ),
      ),
    );
  }

  double _maxY(List<MonthlyPoint> trend) {
    var m = 0.0;
    for (final p in trend) {
      m = m > p.expense ? m : p.expense.toDouble();
      m = m > p.income ? m : p.income.toDouble();
    }
    return m;
  }

  double _niceInterval(List<MonthlyPoint> trend) {
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
                Text('分类分析', style: textTheme.titleMedium),
                const Spacer(),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(value: 0, label: Text('支出')),
                    ButtonSegment(value: 1, label: Text('收入')),
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
                child: Center(child: Text('区间内暂无${_tab == 0 ? '支出' : '收入'}')),
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
                                      share.category?.name ?? '未分类',
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
