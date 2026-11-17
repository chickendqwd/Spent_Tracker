import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction_type.dart';
import '../../state/category_providers.dart';
import '../../state/currency_providers.dart';
import '../../state/recurring_rule_providers.dart';

/// 周期记账管理页（v2）：每周/每月/每年规则增删改、启停。
/// 提醒在总览页「今日待记」提示条出现，点击预填后手动保存入账。
class RecurringRulesPage extends ConsumerWidget {
  const RecurringRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringRuleProvider);
    final categories = ref.watch(categoryProvider);
    final currencies = ref.watch(currencyProvider);
    final categoryByKey = {for (final c in categories) c.key as int: c};
    final currencyByCode = {for (final c in currencies) c.code: c};

    return Scaffold(
      appBar: AppBar(title: const Text('周期记账')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            '设置周期规则后，到期日在总览页出现「今日待记」提示条，'
            '点击预填录入并手动确认入账（不自动记账）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (rules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('尚未设置周期规则\n点右下角「+」添加')),
            )
          else
            for (final r in rules)
              _RuleTile(
                rule: r,
                categoryName: r.categoryId == null
                    ? '未分类'
                    : (categoryByKey[r.categoryId]?.name ?? '未分类'),
                symbol: currencyByCode[r.currency]?.symbol ?? 'S\$',
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增规则'),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_RuleFormResult>(
      context: context,
      builder: (_) => _RuleDialog(
        categories: ref.read(categoryProvider),
        currencies: ref.read(currencyProvider),
      ),
    );
    if (result == null || !context.mounted) return;
    await ref.read(recurringRuleProvider.notifier).add(
          RecurringRule(
            type: result.type,
            amount: result.amountCents,
            categoryId: result.categoryId,
            note: result.note,
            currency: result.currency,
            frequency: result.frequency.index,
            dayValue: result.dayValue,
            startDate: DateUtil.toDayKey(result.startDate),
          ),
        );
  }
}

class _RuleTile extends ConsumerWidget {
  const _RuleTile({
    required this.rule,
    required this.categoryName,
    required this.symbol,
  });

  final RecurringRule rule;
  final String categoryName;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = rule.type == TransactionType.expense.index;
    final prefix = isExpense ? '-' : '+';
    final desc = _frequencyDesc(rule);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$prefix${MoneyUtil.format(rule.amount, symbol: symbol)}',
                    style: TextStyle(
                      color: isExpense
                          ? Theme.of(context).colorScheme.error
                          : const Color(0xFF2F8C6B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  rule.active ? '启用中' : '已停用',
                  style: TextStyle(
                    color: rule.active
                        ? Colors.grey.shade600
                        : Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
                Switch(
                  value: rule.active,
                  onChanged: (_) =>
                      ref.read(recurringRuleProvider.notifier).toggleActive(rule),
                ),
              ],
            ),
            Text(
              '${rule.recurringFrequency.label} · $categoryName'
              '${rule.note == null || rule.note!.isEmpty ? '' : ' · ${rule.note}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$desc · 开始 ${rule.startDate}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
          ],
        ),
      ),
    );
  }

  String _frequencyDesc(RecurringRule r) {
    switch (r.recurringFrequency) {
      case RecurringFrequency.weekly:
        return '每周 ${'周一二三四五六日'[r.dayValue - 1]}';
      case RecurringFrequency.monthly:
        return '每月 ${r.dayValue} 号';
      case RecurringFrequency.yearly:
        return '每年 ${DateUtil.fromDayKey(r.startDate).month} 月 ${r.dayValue} 号';
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_RuleFormResult>(
      context: context,
      builder: (_) => _RuleDialog(
        categories: ref.read(categoryProvider),
        currencies: ref.read(currencyProvider),
        initialType: rule.type,
        initialAmount: MoneyUtil.inputText(rule.amount),
        initialCategoryId: rule.categoryId,
        initialNote: rule.note,
        initialCurrency: rule.currency,
        initialFrequency: rule.recurringFrequency,
        initialDayValue: rule.dayValue,
        initialStartDate: DateUtil.fromDayKey(rule.startDate),
      ),
    );
    if (result == null || !context.mounted) return;
    rule.type = result.type;
    rule.amount = result.amountCents;
    rule.categoryId = result.categoryId;
    rule.note = result.note;
    rule.currency = result.currency;
    rule.frequency = result.frequency.index;
    rule.dayValue = result.dayValue;
    rule.startDate = DateUtil.toDayKey(result.startDate);
    await ref.read(recurringRuleProvider.notifier).update(rule);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条规则？'),
        content: const Text('删除后仅影响后续提醒，不影响已记账目。'),
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
    await ref.read(recurringRuleProvider.notifier).remove(rule.key as int);
  }
}

class _RuleFormResult {
  const _RuleFormResult({
    required this.type,
    required this.amountCents,
    this.categoryId,
    this.note,
    required this.currency,
    required this.frequency,
    required this.dayValue,
    required this.startDate,
  });

  final int type;
  final int amountCents;
  final int? categoryId;
  final String? note;
  final String currency;
  final RecurringFrequency frequency;
  final int dayValue;
  final DateTime startDate;
}

class _RuleDialog extends StatefulWidget {
  _RuleDialog({
    required this.categories,
    required this.currencies,
    this.initialType = 0,
    this.initialAmount,
    this.initialCategoryId,
    this.initialNote,
    this.initialCurrency = 'SGD',
    this.initialFrequency = RecurringFrequency.weekly,
    this.initialDayValue = 1,
    DateTime? initialStartDate,
  }) : initialStartDate = initialStartDate ?? DateTime.now();

  final List<Category> categories;
  final List<Currency> currencies;
  final int initialType;
  final String? initialAmount;
  final int? initialCategoryId;
  final String? initialNote;
  final String initialCurrency;
  final RecurringFrequency initialFrequency;
  final int initialDayValue;
  final DateTime initialStartDate;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late int _type;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  int? _categoryId;
  late String _currency;
  late RecurringFrequency _frequency;
  late int _dayValue;
  late DateTime _startDate;

  static final _amountFormat = RegExp(r'^\d{0,7}(\.\d{0,2})?$');

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _categoryId = widget.initialCategoryId;
    _currency = widget.initialCurrency;
    _frequency = widget.initialFrequency;
    _dayValue = widget.initialDayValue;
    _startDate = widget.initialStartDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeCategories = widget.categories
        .where((c) => c.type == _type)
        .toList(growable: false);

    return AlertDialog(
      title: const Text('周期规则'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('支出')),
                ButtonSegment(value: 1, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 12),
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
                labelText: '金额',
                prefixText:
                    '${widget.currencies.where((c) => c.code == _currency).firstOrNull?.symbol ?? 'S\$'} ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: '币种',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in widget.currencies)
                  DropdownMenuItem(value: c.code, child: Text('${c.symbol} ${c.name}')),
              ],
              onChanged: (v) => setState(() => _currency = v ?? 'SGD'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecurringFrequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(
                labelText: '频率',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: RecurringFrequency.weekly,
                  child: Text('每周'),
                ),
                DropdownMenuItem(
                  value: RecurringFrequency.monthly,
                  child: Text('每月'),
                ),
                DropdownMenuItem(
                  value: RecurringFrequency.yearly,
                  child: Text('每年'),
                ),
              ],
              onChanged: (v) => setState(() {
                _frequency = v ?? RecurringFrequency.weekly;
                _dayValue = 1;
              }),
            ),
            const SizedBox(height: 12),
            // 触发日：weekly 选周几；monthly/yearly 选几号
            if (_frequency == RecurringFrequency.weekly)
              DropdownButtonFormField<int>(
                initialValue: _dayValue,
                decoration: const InputDecoration(
                  labelText: '每周几',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var i = 1; i <= 7; i++)
                    DropdownMenuItem(value: i, child: Text('周${'一二三四五六日'[i - 1]}')),
                ],
                onChanged: (v) => setState(() => _dayValue = v ?? 1),
              )
            else
              TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: TextEditingController(text: '$_dayValue'),
                decoration: const InputDecoration(
                  labelText: '几号（1-31）',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v) ?? 1;
                  _dayValue = n.clamp(1, 31);
                },
              ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text('开始日期：${DateUtil.listHeader(_startDate)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 4),
            if (_type == 0 || _type == 1)
              _buildCategoryChips(typeCategories),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
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
            final note = _noteController.text.trim();
            Navigator.of(context).pop(
              _RuleFormResult(
                type: _type,
                amountCents: cents,
                categoryId: _categoryId ??
                    (typeCategories.isEmpty ? null : typeCategories.first.key as int),
                note: note.isEmpty ? null : note,
                currency: _currency,
                frequency: _frequency,
                dayValue: _dayValue,
                startDate: _startDate,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(List<Category> typeCategories) {
    if (typeCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text('请先添加该类型分类'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('分类', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in typeCategories)
              ChoiceChip(
                avatar: Text(c.displayIcon),
                label: Text(c.name),
                selected: c.key == _categoryId,
                onSelected: (_) => setState(() => _categoryId = c.key as int),
              ),
          ],
        ),
      ],
    );
  }
}
