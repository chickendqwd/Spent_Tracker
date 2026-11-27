import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../l10n/l10n.dart';
import '../../state/currency_providers.dart';
import 'surfaces.dart';

/// 单条账目展示（总览「最近记录」与「明细」列表共用）。
/// 浅灰圆形 Emoji 头像 + 分类名 + 备注 + 语义色金额。
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
    final l10n = context.l10n;
    final palette = context.palette;
    final isExpense = transaction.transactionType == TransactionType.expense;
    final prefix =
        isExpense ? AppConstants.expensePrefix : AppConstants.incomePrefix;
    final color = isExpense ? palette.expense : palette.income;
    // 列表/详情显示原记账币种符号（agent v2 4.8）
    final symbol = symbolOf(ref.watch(currencyProvider), transaction.currency);
    final note = transaction.note?.trim() ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            EmojiBadge(emoji: category?.displayIcon ?? '📦', size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categoryDisplayName(l10n, category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                      height: 1.25,
                    ),
                  ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.muted,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$prefix${MoneyUtil.format(transaction.amount, symbol: symbol)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
