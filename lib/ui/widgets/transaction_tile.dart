import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../state/currency_providers.dart';

/// 单条账目展示（总览「最近记录」与「明细」列表共用）。
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
  });

  final Transaction transaction;

  /// 该账目的分类；null 表示「未分类」
  final Category? category;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.transactionType == TransactionType.expense;
    final prefix = isExpense
        ? AppConstants.expensePrefix
        : AppConstants.incomePrefix;
    final color = isExpense
        ? context.palette.expense
        : context.palette.income;
    // 列表/详情显示原记账币种符号（agent v2 4.8）
    final symbol = symbolOf(ref.watch(currencyProvider), transaction.currency);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          category?.displayIcon ?? '📦',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text(category?.name ?? '未分类'),
      subtitle: transaction.note == null || transaction.note!.isEmpty
          ? null
          : Text(
              transaction.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Text(
        '$prefix${MoneyUtil.format(transaction.amount, symbol: symbol)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}
