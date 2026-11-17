import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money_util.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../state/budget_providers.dart';
import '../../state/category_providers.dart';

/// 预算设置页（v2）：管理月度总预算与分类预算。
/// 按「月」记录，页面只编辑当前月预算；删除需二次确认。
class BudgetSettingsPage extends ConsumerWidget {
  const BudgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(effectiveBudgetsProvider);
    final categories = ref.watch(categoryProvider);
    final categoryByKey = {for (final c in categories) c.key as int: c};
    final month = ref.watch(budgetMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('预算设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text('当前月：$month', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (budgets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('本月尚未设置预算\n点右下角「+」添加')),
            )
          else
            for (final b in budgets)
              _BudgetTile(
                budget: b,
                categoryByKey: categoryByKey,
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增预算'),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_BudgetFormResult>(
      context: context,
      builder: (_) => _BudgetDialog(categories: ref.read(categoryProvider)),
    );
    if (result == null || !context.mounted) return;
    final month = ref.read(budgetMonthProvider);
    await ref.read(budgetProvider.notifier).add(
          Budget(
            type: result.type.index,
            categoryId: result.type == BudgetType.category
                ? result.categoryId
                : null,
            month: month,
            amount: result.amountCents,
          ),
        );
  }
}

/// 当前月 yyyy-MM（预算设置的目标月份）。
final budgetMonthProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
});

class _BudgetTile extends ConsumerWidget {
  const _BudgetTile({required this.budget, required this.categoryByKey});

  final Budget budget;
  final Map<int, Category> categoryByKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTotal = budget.budgetType == BudgetType.total;
    final label = isTotal
        ? '总预算'
        : '分类预算 · ${budget.categoryId == null ? '未分类' : (categoryByKey[budget.categoryId]?.name ?? '未知')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          isTotal ? Icons.savings_outlined : Icons.category_outlined,
        ),
        title: Text(label),
        subtitle: Text('所属月：${budget.month}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MoneyUtil.format(budget.amount, symbol: 'S\$ '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑',
              onPressed: () => _edit(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_BudgetFormResult>(
      context: context,
      builder: (_) => _BudgetDialog(
        categories: ref.read(categoryProvider),
        initialType: budget.budgetType,
        initialAmount: MoneyUtil.inputText(budget.amount),
        initialCategoryId: budget.categoryId,
      ),
    );
    if (result == null || !context.mounted) return;
    budget.type = result.type.index;
    budget.categoryId = result.type == BudgetType.category
        ? result.categoryId
        : null;
    budget.amount = result.amountCents;
    await ref.read(budgetProvider.notifier).update(budget);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这笔预算？'),
        content: const Text('删除后仅影响后续，不影响历史账目。'),
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
    await ref.read(budgetProvider.notifier).remove(budget.key as int);
  }
}

class _BudgetFormResult {
  const _BudgetFormResult({
    required this.type,
    required this.amountCents,
    this.categoryId,
  });

  final BudgetType type;
  final int amountCents;
  final int? categoryId;
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({
    required this.categories,
    this.initialType = BudgetType.total,
    this.initialAmount,
    this.initialCategoryId,
  });

  final List<Category> categories;
  final BudgetType initialType;
  final String? initialAmount;
  final int? initialCategoryId;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late BudgetType _type;
  late final TextEditingController _amountController;
  int? _categoryId;

  static final _amountFormat = RegExp(r'^\d{0,7}(\.\d{0,2})?$');

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = widget.categories
        .where((c) => c.type == 0)
        .toList(growable: false);

    return AlertDialog(
      title: const Text('预算'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<BudgetType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: BudgetType.total, label: Text('总预算')),
                ButtonSegment(
                  value: BudgetType.category,
                  label: Text('分类预算'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                if (_type == BudgetType.total) _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      _amountFormat.hasMatch(newValue.text) ? newValue : oldValue,
                ),
              ],
              decoration: const InputDecoration(
                labelText: '金额（SGD）',
                prefixText: 'S\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            if (_type == BudgetType.category) ...[
              const SizedBox(height: 16),
              const Text('分类', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (expenseCategories.isEmpty)
                const Text('请先添加支出分类')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in expenseCategories)
                      ChoiceChip(
                        avatar: Text(c.displayIcon),
                        label: Text(c.name),
                        selected: c.key == _categoryId,
                        onSelected: (_) =>
                            setState(() => _categoryId = c.key as int),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final cents = MoneyUtil.parseToCents(_amountController.text);
            if (cents == null || cents <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入有效金额')),
              );
              return;
            }
            Navigator.of(context).pop(
              _BudgetFormResult(
                type: _type,
                amountCents: cents,
                categoryId: _type == BudgetType.category
                    ? (_categoryId ??
                        (expenseCategories.isEmpty
                            ? null
                            : expenseCategories.first.key as int))
                    : null,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
