import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money_util.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../l10n/l10n.dart';
import '../../state/budget_providers.dart';
import '../../state/category_providers.dart';
import '../../state/currency_providers.dart';

/// 预算设置页（v2）：管理月度总预算与分类预算。
/// 按「月」记录，页面只编辑当前月预算；删除需二次确认。
class BudgetSettingsPage extends ConsumerWidget {
  const BudgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final budgets = ref.watch(effectiveBudgetsProvider);
    final categories = ref.watch(categoryProvider);
    final categoryByKey = {for (final c in categories) c.key as int: c};
    final month = ref.watch(budgetMonthProvider);
    final currencies = ref.watch(currencyProvider);
    final base = ref.watch(baseCurrencyProvider);
    final budgetCurrencySetting = ref.watch(budgetCurrencyProvider);
    Currency? budgetCurrency;
    if (budgetCurrencySetting != null) {
      for (final c in currencies) {
        if (c.code == budgetCurrencySetting) {
          budgetCurrency = c;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            l10n.budgetsCurrentMonth(month),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.budgetsIntro(currencyDisplayName(l10n, base)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.currency_exchange),
            title: Text(l10n.budgetsDefaultCurrency),
            subtitle: Text(
              budgetCurrency == null
                  ? l10n.budgetsCurrencyFollowBase
                  : currencyDisplayName(l10n, budgetCurrency),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickDefaultCurrency(context, ref, currencies, base),
          ),
          const Divider(height: 8),
          if (budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text(l10n.budgetsEmpty)),
            )
          else
            for (final b in budgets)
              _BudgetTile(
                budget: b,
                categoryByKey: categoryByKey,
                currencies: currencies,
                base: base,
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.budgetsAdd),
      ),
    );
  }

  /// 选择全局默认预算币种：跟随基准币种，或任一具体币种。
  Future<void> _pickDefaultCurrency(
    BuildContext context,
    WidgetRef ref,
    List<Currency> currencies,
    Currency base,
  ) async {
    final l10n = context.l10n;
    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.budgetsDefaultCurrency),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(kFollowBaseCurrency),
            child: Row(
              children: [
                Text(l10n.budgetsCurrencyFollowBase),
                const SizedBox(width: 6),
                Text(
                  '(${currencyDisplayName(l10n, base)})',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (final c in currencies)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(c.code),
              child: Text('${c.symbol} ${currencyDisplayName(l10n, c)}'),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await ref
        .read(budgetCurrencyProvider.notifier)
        .set(selected == kFollowBaseCurrency ? null : selected);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final currencies = ref.read(currencyProvider);
    final result = await showDialog<_BudgetFormResult>(
      context: context,
      builder: (_) => _BudgetDialog(
        categories: ref.read(categoryProvider),
        currencies: currencies,
        initialCurrency: defaultBudgetCurrencyCode(
          currencies,
          ref.read(budgetCurrencyProvider),
        ),
      ),
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
            // 金额与币种一起存，展示时再换算到基准
            amount: result.amountCents,
            currency: result.currency,
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
  const _BudgetTile({
    required this.budget,
    required this.categoryByKey,
    required this.currencies,
    required this.base,
  });

  final Budget budget;
  final Map<int, Category> categoryByKey;
  final List<Currency> currencies;
  final Currency base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isTotal = budget.budgetType == BudgetType.total;
    final category = budget.categoryId == null
        ? null
        : categoryByKey[budget.categoryId];
    final name = category == null && budget.categoryId != null
        ? l10n.commonUnknown
        : categoryDisplayName(l10n, category);
    final label = isTotal
        ? l10n.budgetTypeTotal
        : l10n.budgetsCategoryWith(name);
    // 主显示为预算自身币种的金额；与基准不同时附「≈ 基准值」
    final code = budget.currencyCode;
    final symbol = symbolOf(currencies, code);
    final amountInBase = budgetCentsInBase(currencies, budget.amount, code);
    final approxBase = code == baseCodeOf(currencies)
        ? null
        : l10n.budgetsApprox(
            MoneyUtil.format(amountInBase, symbol: '${base.symbol} '),
          );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          isTotal ? Icons.savings_outlined : Icons.category_outlined,
        ),
        title: Text(label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.budgetsMonthLabel(budget.month)),
            if (approxBase != null)
              Text(approxBase, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MoneyUtil.format(budget.amount, symbol: '$symbol '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.commonEdit,
              onPressed: () => _edit(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.commonDelete,
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
        currencies: currencies,
        initialCurrency: budget.currencyCode,
        initialType: budget.budgetType,
        // 编辑时展示原录入值（原币种金额），而不是换算后的基准值
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
    budget.currency = result.currency;
    await ref.read(budgetProvider.notifier).update(budget);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.budgetsDeleteTitle),
        content: Text(l10n.budgetsDeleteBody),
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
    await ref.read(budgetProvider.notifier).remove(budget.key as int);
  }
}

class _BudgetFormResult {
  const _BudgetFormResult({
    required this.type,
    required this.amountCents,
    required this.currency,
    this.categoryId,
  });

  final BudgetType type;
  final int amountCents;
  final String currency;
  final int? categoryId;
}

/// 默认币种选择器里代表「跟随基准币种」的哨兵值（不会与真实币种 code 冲突）。
const kFollowBaseCurrency = '__follow_base_currency__';

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({
    required this.categories,
    required this.currencies,
    required this.initialCurrency,
    this.initialType = BudgetType.total,
    this.initialAmount,
    this.initialCategoryId,
  });

  final List<Category> categories;
  final List<Currency> currencies;

  /// 录入币种（新增时为默认币种，编辑时为该预算原币种）
  final String initialCurrency;
  final BudgetType initialType;
  final String? initialAmount;
  final int? initialCategoryId;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late BudgetType _type;
  late final TextEditingController _amountController;
  late String _currency;
  int? _categoryId;

  static final _amountFormat = RegExp(r'^\d{0,7}(\.\d{0,2})?$');

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
    _currency = widget.initialCurrency;
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expenseCategories = widget.categories
        .where((c) => c.type == 0)
        .toList(growable: false);
    final symbol = symbolOf(widget.currencies, _currency);

    return AlertDialog(
      title: Text(l10n.budgetsDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<BudgetType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: BudgetType.total,
                  label: Text(l10n.budgetTypeTotal),
                ),
                ButtonSegment(
                  value: BudgetType.category,
                  label: Text(l10n.budgetTypeCategory),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                if (_type == BudgetType.total) _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(
                labelText: l10n.budgetsCurrency,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final c in widget.currencies)
                  DropdownMenuItem(
                    value: c.code,
                    child: Text(
                      '${c.symbol} ${currencyDisplayName(l10n, c)}',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _currency = v ?? _currency),
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
              decoration: InputDecoration(
                labelText: l10n.budgetsAmountLabel(_currency),
                prefixText: '$symbol ',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_type == BudgetType.category) ...[
              const SizedBox(height: 16),
              Text(
                l10n.commonCategory,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (expenseCategories.isEmpty)
                Text(l10n.budgetsAddExpenseFirst)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in expenseCategories)
                      ChoiceChip(
                        avatar: Text(c.displayIcon),
                        label: Text(categoryDisplayName(l10n, c)),
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
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final cents = MoneyUtil.parseToCents(_amountController.text);
            if (cents == null || cents <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.budgetsInvalidAmount)),
              );
              return;
            }
            Navigator.of(context).pop(
              _BudgetFormResult(
                type: _type,
                amountCents: cents,
                currency: _currency,
                categoryId: _type == BudgetType.category
                    ? (_categoryId ??
                        (expenseCategories.isEmpty
                            ? null
                            : expenseCategories.first.key as int))
                    : null,
              ),
            );
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
