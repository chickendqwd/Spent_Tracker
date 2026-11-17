import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../state/category_providers.dart';
import '../../state/currency_providers.dart';
import '../../state/transaction_providers.dart';
import 'add_transaction_sheet.dart';

/// 账目详情面板：查看、编辑（二次确认）、删除（二次确认）。
class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({super.key, required this.transaction});

  final Transaction transaction;

  static Future<void> show(BuildContext context, Transaction t) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionDetailSheet(transaction: t),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final t = transaction;
    Navigator.of(context).pop(); // 关闭详情
    await AddTransactionSheet.show(context, existing: t);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = transaction;
    final symbol = ref
            .read(currencyProvider)
            .where((c) => c.code == t.currency)
            .firstOrNull
            ?.symbol ??
        'S\$';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这笔记录？'),
        content: Text(
          '${t.transactionType == TransactionType.expense ? '支出' : '收入'} '
          '${MoneyUtil.format(t.amount, symbol: symbol)}，删除后不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(transactionProvider.notifier).remove(t.key as int);
    if (context.mounted) Navigator.of(context).pop(); // 关闭详情
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final category = transaction.categoryId == null
        ? null
        : categories.where((c) => c.key == transaction.categoryId).firstOrNull;
    final symbol = ref
            .watch(currencyProvider)
            .where((c) => c.code == transaction.currency)
            .firstOrNull
            ?.symbol ??
        'S\$';
    final isExpense = transaction.transactionType == TransactionType.expense;
    final color = isExpense
        ? AppConstants.expenseColor
        : AppConstants.incomeColor;
    final prefix = isExpense
        ? AppConstants.expensePrefix
        : AppConstants.incomePrefix;

    final rows = <(String, String)>[
      ('类型', transaction.transactionType.label),
      ('金额', MoneyUtil.format(transaction.amount, symbol: symbol)),
      ('币种', transaction.currency),
      ('分类', category?.name ?? '未分类'),
      ('日期', DateUtil.listHeader(DateUtil.fromDayKey(transaction.date))),
      if (transaction.note != null && transaction.note!.isNotEmpty)
        ('备注', transaction.note!),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('账目详情', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  category?.displayIcon ?? '📦',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$prefix${MoneyUtil.format(transaction.amount, symbol: symbol)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      label,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(child: Text(value)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                  onPressed: () => _edit(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                  onPressed: () => _delete(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
