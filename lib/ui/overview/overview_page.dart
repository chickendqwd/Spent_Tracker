import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../state/category_providers.dart';
import '../../state/summary_providers.dart';
import '../../state/transaction_providers.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';

/// 总览页（首页）：本月总支出/总收入/结余、支出分类占比、最近记录。
/// 总结闭环：打开 → 看总账 → 看分类占比。
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoryProvider);
    final categoryByKey = {for (final c in categories) c.key as int: c};

    return Scaffold(
      appBar: AppBar(
        title: Text('本月总览 · ${DateUtil.monthTitle(DateTime.now())}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // 总账三卡片
          Row(
            children: [
              _StatCard(
                label: '总支出',
                amount: summary.totalExpense,
                color: AppConstants.expenseColor,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: '总收入',
                amount: summary.totalIncome,
                color: AppConstants.incomeColor,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: '结余',
                amount: summary.balance,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 分类占比
          _CategoryBreakdownCard(summary: summary),
          const SizedBox(height: 16),
          // 最近记录
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('最近记录', style: Theme.of(context).textTheme.titleMedium),
                  if (recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('还没有记录，点右下角「+」记一笔吧')),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

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
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  MoneyUtil.format(amount),
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

/// 支出分类占比卡片：环形图 + 图例（金额、占比）。
class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shares = summary.expenseByCategory;
    final total = summary.totalExpense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('支出分类占比', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            if (total == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('本月暂无支出')),
              )
            else ...[
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 44,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                          sections: [
                            for (final (i, share) in shares.indexed)
                              PieChartSectionData(
                                value: share.amountCents.toDouble(),
                                color:
                                    AppConstants.chartPalette[i %
                                        AppConstants.chartPalette.length],
                                radius: 52,
                                title:
                                    '${(share.amountCents / total * 100).toStringAsFixed(0)}%',
                                titleStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 图例
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
                                      color:
                                          AppConstants.chartPalette[i %
                                              AppConstants.chartPalette.length],
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
                                    MoneyUtil.format(share.amountCents),
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
          ],
        ),
      ),
    );
  }
}
