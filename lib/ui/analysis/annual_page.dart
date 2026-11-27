import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_util.dart';
import '../../l10n/l10n.dart';
import '../../state/annual_providers.dart';
import '../../state/currency_providers.dart';

/// 年度报告（v3 更多分析）：
/// 年份切换 → 全年收支三卡片 → 关键统计（笔数/月均/最高支出月）
/// → 12 个月收支柱状图 → 分类排行（支出/收入 Tab）。
class AnnualPage extends ConsumerWidget {
  const AnnualPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(annualSummaryProvider);
    final symbol = ref.watch(baseCurrencyProvider).symbol;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.annualTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _YearSwitcher(),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: l10n.annualYearlyExpense,
                amount: summary.totalExpense,
                color: palette.expense,
                symbol: symbol,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: l10n.annualYearlyIncome,
                amount: summary.totalIncome,
                color: palette.income,
                symbol: symbol,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: l10n.annualBalance,
                amount: summary.balance,
                color: Theme.of(context).colorScheme.onSurface,
                symbol: symbol,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Row(
                children: [
                  _KeyStat(
                    label: l10n.annualRecordCount,
                    value: l10n.commonUnitEntries('${summary.recordCount}'),
                  ),
                  _KeyStat(
                    label: l10n.annualAvgExpense,
                    value: MoneyUtil.format(
                      summary.averageMonthlyExpense,
                      symbol: symbol,
                    ),
                  ),
                  _KeyStat(
                    label: l10n.annualPeakMonth,
                    value: summary.peakExpenseMonth == 0
                        ? l10n.commonNone
                        : l10n.monthShort('${summary.peakExpenseMonth}'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (summary.recordCount == 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text(l10n.annualNoRecords)),
              ),
            )
          else ...[
            _MonthlyBarCard(summary: summary, symbol: symbol),
            const SizedBox(height: 16),
            _CategoryRankCard(summary: summary, symbol: symbol),
          ],
        ],
      ),
    );
  }
}

/// 年份切换：可向前回看历史年份，不允许超过今年。
class _YearSwitcher extends ConsumerWidget {
  const _YearSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final year = ref.watch(annualYearProvider);
    final now = DateTime.now().year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.annualPrevYear,
          onPressed: () => ref.read(annualYearProvider.notifier).previous(),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          l10n.yearLabelOf(year),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        IconButton(
          tooltip: l10n.annualNextYear,
          onPressed: year >= now
              ? null
              : () => ref.read(annualYearProvider.notifier).next(),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
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
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.muted,
                ),
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

class _KeyStat extends StatelessWidget {
  const _KeyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: context.palette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 12 个月收支双柱图（支出 / 收入）。
class _MonthlyBarCard extends StatelessWidget {
  const _MonthlyBarCard({required this.summary, required this.symbol});

  final AnnualSummary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    var maxCents = 0.0;
    for (final m in summary.months) {
      if (m.expense > maxCents) maxCents = m.expense.toDouble();
      if (m.income > maxCents) maxCents = m.income.toDouble();
    }
    final maxY = maxCents <= 0 ? 1000.0 : maxCents * 1.15;
    final interval = maxCents <= 0 ? 1000.0 : maxCents / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                // C10：柱状图 X 轴只有月份数字，标题里补上所属年份
                l10n.annualChartTitle('${summary.year}'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (v, _) => Text(
                          (v / 100).toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.muted,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, _) => Text(
                          '${v.round() + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < summary.months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 2,
                        barRods: [
                          BarChartRodData(
                            toY: summary.months[i].expense.toDouble(),
                            color: palette.expense,
                            width: 5,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          BarChartRodData(
                            toY: summary.months[i].income.toDouble(),
                            color: palette.income,
                            width: 5,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _LegendDot(label: l10n.typeExpense, color: palette.expense),
                ),
                const SizedBox(width: 16),
                _LegendDot(label: l10n.typeIncome, color: palette.income),
                const Spacer(),
                Text(
                  l10n.annualUnit(symbol),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 分类排行（支出/收入 Tab），按金额降序。
class _CategoryRankCard extends ConsumerStatefulWidget {
  const _CategoryRankCard({required this.summary, required this.symbol});

  final AnnualSummary summary;
  final String symbol;

  @override
  ConsumerState<_CategoryRankCard> createState() => _CategoryRankCardState();
}

class _CategoryRankCardState extends ConsumerState<_CategoryRankCard> {
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
                Text(l10n.annualCategoryRanking, style: textTheme.titleMedium),
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
            const SizedBox(height: 12),
            if (shares.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _tab == 0 ? l10n.annualNoExpense : l10n.annualNoIncome,
                  ),
                ),
              )
            else
              for (final (i, share) in shares.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryDisplayName(l10n, share.category),
                          style: textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(share.amountCents / total * 100).toStringAsFixed(0)}%',
                        style: textTheme.bodySmall
                            ?.copyWith(color: context.palette.muted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        MoneyUtil.format(share.amountCents,
                            symbol: widget.symbol),
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
