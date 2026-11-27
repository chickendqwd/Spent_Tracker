import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/trend_analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/category.dart';
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
import '../widgets/surfaces.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';

/// 总览页（UI 重构）：
/// 时间范围切换 → 今日待记提示 → 结余主卡（支出/收入两格）
/// → 本月预算 → 收支趋势 → 分类分析 → 最近记录。
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
        title: SectionTitle(l10n.overviewTitle),
        actions: [
          IconButton(
            tooltip: l10n.overviewAnnualTooltip,
            icon: const Icon(Icons.calendar_view_month_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnualPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
          children: [
            const TimeRangeSelector(),
            if (dueRules.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TodayDueBanner(rules: dueRules),
            ],
            const SizedBox(height: 14),
            _BalanceCard(
              balance: summary.balance,
              expense: summary.totalExpense,
              income: summary.totalIncome,
              symbol: baseSymbol,
            ),
            if (totalBudget != null) ...[
              const SizedBox(height: 14),
              _BudgetCard(
                // 预算按自身币种存储，展示前换算到当前基准币种
                budgetAmount: budgetCentsInBase(
                  currencies,
                  totalBudget.amount,
                  totalBudget.currencyCode,
                ),
                used: thisMonthExpense,
                symbol: baseSymbol,
              ),
            ],
            const SizedBox(height: 14),
            _TrendCard(symbol: baseSymbol),
            const SizedBox(height: 14),
            _CategoryAnalysisCard(summary: summary, symbol: baseSymbol),
            const SizedBox(height: 14),
            _RecentCard(
              recent: recent,
              categoryByKey: categoryByKey,
            ),
          ],
        ),
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
    final palette = context.palette;

    return SlantCard(
      accentColor: palette.accent,
      tint: true,
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
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
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available, size: 18, color: palette.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.overviewTodayDue('${rules.length}'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: palette.muted),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

/// 结余主卡：大号结余数字为全页第一焦点，下方并排支出 / 收入。
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.expense,
    required this.income,
    required this.symbol,
  });

  final int balance;
  final int expense;
  final int income;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    const onHero = Colors.white;
    final onHeroMuted = Colors.white.withValues(alpha: 0.72);
    final onHeroLine = Colors.white.withValues(alpha: 0.16);

    return SlantCard(
      background: palette.primaryDeep,
      accentColor: palette.accent,
      elevation: 2.6,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.overviewBalance,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: onHero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyUtil.format(balance, symbol: symbol),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.1,
                color: onHero,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: onHeroLine),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l10n.overviewTotalExpense,
                  amount: expense,
                  symbol: symbol,
                  color: onHero,
                  labelColor: onHeroMuted,
                ),
              ),
              Container(width: 1, height: 30, color: onHeroLine),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniStat(
                  label: l10n.overviewTotalIncome,
                  amount: income,
                  symbol: symbol,
                  color: onHero,
                  labelColor: onHeroMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
    this.labelColor,
  });

  final String label;
  final int amount;
  final String symbol;
  final Color color;

  /// 标签文字颜色（深色主卡上使用半透明白）
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: labelColor ?? palette.muted,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            MoneyUtil.format(amount, symbol: symbol),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// 本月预算：已用 / 总额进度条；超支标红。
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
    final palette = context.palette;
    final over = used > budgetAmount;
    final progress =
        budgetAmount <= 0 ? 0.0 : (used / budgetAmount).clamp(0.0, 1.0);
    final color = over ? palette.expense : palette.primary;

    return SlantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: context.l10n.overviewMonthlyBudget,
            trailing: Text(
              '${MoneyUtil.format(used, symbol: symbol)} / ${MoneyUtil.format(budgetAmount, symbol: symbol)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: color,
              backgroundColor: palette.divider,
            ),
          ),
          if (over) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline, size: 13, color: palette.expense),
                const SizedBox(width: 4),
                Text(
                  context.l10n.overviewOverBudget,
                  style: TextStyle(fontSize: 12, color: palette.expense),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 收支趋势折线图：区间可切（本周/本月/近3月/近6月/近12月），
/// 按区间步长降采样，呈现日间波动；双线（支出、收入）。
class _TrendCard extends ConsumerWidget {
  const _TrendCard({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final trend = ref.watch(trendProvider);
    final range = ref.watch(trendRangeProvider);

    return SlantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: l10n.overviewTrendTitle),
          const SizedBox(height: 10),
          _TrendRangePicker(
            current: range,
            onChanged: (r) => ref.read(trendRangeProvider.notifier).set(r),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
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
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: palette.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: _niceInterval(trend),
                      getTitlesWidget: (v, meta) => Text(
                        (v / 100).toStringAsFixed(0),
                        style: TextStyle(fontSize: 10, color: palette.muted),
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
                                  color: palette.muted,
                                ),
                              ),
                              Text(
                                l10n.weekdayChar(trend[i].start.weekday),
                                style: TextStyle(
                                  fontSize: 9,
                                  height: 1.1,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          trend[i].shortLabel,
                          style: TextStyle(fontSize: 10, color: palette.muted),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => palette.primaryDeep,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          _tooltipText(l10n, s, trend),
                          TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  _line(
                    trend,
                    (b) => b.expense,
                    palette.expense,
                  ),
                  _line(
                    trend,
                    (b) => b.income,
                    palette.income,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(context, l10n.typeExpense, palette.expense),
              const SizedBox(width: 16),
              _legendDot(context, l10n.typeIncome, palette.income),
            ],
          ),
        ],
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

  Widget _legendDot(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: context.palette.muted),
        ),
      ],
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
      curveSmoothness: 0.2,
      color: color,
      barWidth: 2.2,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
          radius: spot.x == last ? 3.2 : 1.8,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.0),
          ],
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
    final factor = firstDigit <= 1
        ? 1.0
        : (firstDigit <= 2 ? 2.0 : (firstDigit <= 5 ? 5.0 : 10.0));
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
          PillChip(
            label: l10n.trendRange(r),
            selected: current == r,
            onTap: () => onChanged(r),
          ),
        if (overflowSelected)
          // 选中长区间时把当前档位显示出来，避免「没有选中项」的错觉
          PillChip(
            label: l10n.trendRange(current),
            selected: true,
            onTap: () => onChanged(current),
          ),
        // 「更多…」入口常驻：默认选中近 6 月时也要能切到近 12 月
        PopupMenuButton<TrendRange>(
          tooltip: l10n.trendMoreRanges,
          onSelected: onChanged,
          color: context.palette.card,
          itemBuilder: (_) => [
            for (final r in TrendRange.overflow)
              PopupMenuItem(value: r, child: Text(l10n.trendRange(r))),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.palette.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.palette.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.commonMore,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.palette.muted,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 15,
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

/// 分类分析：支出 / 收入切换，环形图占比 + 金额排行。
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
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final shares = _tab == 0
        ? widget.summary.expenseByCategory
        : widget.summary.incomeByCategory;
    final total =
        _tab == 0 ? widget.summary.totalExpense : widget.summary.totalIncome;

    return SlantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: l10n.overviewCategoryAnalysis,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillChip(
                  label: l10n.typeExpense,
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 6),
                PillChip(
                  label: l10n.typeIncome,
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
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
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            centerSpaceRadius: 34,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                            sections: [
                              for (final (i, share) in shares.indexed)
                                PieChartSectionData(
                                  value: share.amountCents.toDouble(),
                                  color: palette.chartPalette[
                                      i % palette.chartPalette.length],
                                  radius: 42,
                                  title:
                                      '${(share.amountCents / total * 100).toStringAsFixed(0)}%',
                                  titleStyle: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: palette.onChartLabel,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (total / 100).toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                            Text(
                              widget.symbol,
                              style: TextStyle(
                                fontSize: 10,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (i, share) in shares.take(5).indexed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: palette.chartPalette[
                                        i % palette.chartPalette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    categoryDisplayName(l10n, share.category),
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: palette.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // 金额随可用宽度缩放，极端大额也不会撑破行
                                Expanded(
                                  flex: 3,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      MoneyUtil.format(
                                        share.amountCents,
                                        symbol: widget.symbol,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: palette.ink,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    '${(share.amountCents / total * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.muted,
                                    ),
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
    );
  }
}

/// 最近记录：标题 + 「查看全部」入口 + 列表。
class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.recent, required this.categoryByKey});

  final List<Transaction> recent;
  final Map<int, Category> categoryByKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return SlantCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CardHeader(title: l10n.overviewRecent),
              ),
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
          const SizedBox(height: 4),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 8, 20),
              child: Center(
                child: Text(
                  l10n.overviewRecentEmpty,
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ),
            )
          else
            for (final (i, t) in recent.indexed) ...[
              TransactionTile(
                transaction: t,
                category: t.categoryId == null
                    ? null
                    : categoryByKey[t.categoryId],
                onTap: () => TransactionDetailSheet.show(context, t),
              ),
              if (i != recent.length - 1)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(height: 1, color: palette.divider),
                ),
            ],
        ],
      ),
    );
  }
}
