import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    final t = transaction;
    final symbol = symbolOf(ref.read(currencyProvider), t.currency);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.detailDeleteTitle),
        content: Text(
          l10n.detailDeleteBody(
            l10n.txType(t.transactionType),
            MoneyUtil.format(t.amount, symbol: symbol),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
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
    final l10n = context.l10n;
    final categories = ref.watch(categoryProvider);
    final category = transaction.categoryId == null
        ? null
        : categories.where((c) => c.key == transaction.categoryId).firstOrNull;
    final symbol =
        symbolOf(ref.watch(currencyProvider), transaction.currency);
    final isExpense = transaction.transactionType == TransactionType.expense;
    final color = isExpense
        ? context.palette.expense
        : context.palette.income;
    final prefix = isExpense
        ? AppConstants.expensePrefix
        : AppConstants.incomePrefix;

    final rows = <(String, String)>[
      (l10n.commonType, l10n.txType(transaction.transactionType)),
      (l10n.commonAmount, MoneyUtil.format(transaction.amount, symbol: symbol)),
      (l10n.commonCurrency, transaction.currency),
      (l10n.commonCategory, categoryDisplayName(l10n, category)),
      (
        l10n.commonDate,
        l10n.dateHeader(DateUtil.fromDayKey(transaction.date)),
      ),
      if (transaction.note != null && transaction.note!.isNotEmpty)
        (l10n.commonNote, transaction.note!),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.detailTitle,
                  style: Theme.of(context).textTheme.titleLarge),
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
                      style: TextStyle(color: context.palette.muted),
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
                  label: Text(l10n.commonEdit),
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
                  label: Text(l10n.commonDelete),
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
