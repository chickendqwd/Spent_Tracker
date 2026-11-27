import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../l10n/l10n.dart';
import '../../state/budget_providers.dart';
import '../../state/category_providers.dart';
import '../../state/currency_providers.dart';
import '../../state/transaction_providers.dart';

/// 「记一笔 / 编辑账目」弹出面板（悬浮「+」入口）。
/// 录入闭环 ≤3 步：填金额 → 选分类 → 保存（默认今天、金额键盘优先）。
/// v2：支持币种选择与周期记账「今日待记」预填；保存时若将超支预算给出轻提示（不强制）。
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.existing, this.prefill});

  /// 传入则为编辑模式，否则为新增。
  final Transaction? existing;

  /// 新增模式的预填值（如周期记账「今日待记」），编辑模式忽略。
  final Transaction? prefill;

  static Future<void> show(
    BuildContext context, {
    Transaction? existing,
    Transaction? prefill,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTransactionSheet(existing: existing, prefill: prefill),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

/// 金额输入格式化：整数位≤7，小数位≤2（元）。
/// 被拦截时回调 [onRejected]，让界面能给出明确提示（v3.2 · C11），而不是静默吞掉输入。
class _AmountInputFormatter extends TextInputFormatter {
  _AmountInputFormatter({required this.onRejected});

  final VoidCallback onRejected;

  static final _pattern = RegExp(r'^\d{0,7}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_pattern.hasMatch(newValue.text)) return newValue;
    onRejected();
    return oldValue;
  }
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late int? _categoryId;
  late DateTime _date;
  late String _currency;
  String? _amountError;
  bool _showCategoryError = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final prefill = widget.prefill;
    final seed = existing ?? prefill;
    _type = seed?.transactionType ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: seed == null ? '' : MoneyUtil.inputText(seed.amount),
    );
    _noteController = TextEditingController(text: seed?.note ?? '');
    _categoryId = seed?.categoryId;
    _date = seed == null
        ? DateTime.now()
        : DateUtil.fromDayKey(seed.date);
    // 币种：编辑/预填沿用其币种；新增默认当前基准币种
    _currency = seed?.currency ?? ref.read(baseCurrencyProvider).code;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 切换支出/收入后，默认选中该类型第一个分类。
  void _switchType(TransactionType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      final list = ref.read(categoryProvider.notifier).ofType(type.index);
      _categoryId = list.isEmpty ? null : list.first.key as int;
    });
  }

  /// 保存后将超出预算的轻提示文本；无则 null。读取保存前状态判断「将超出」。
  String? _overBudgetWarning(int cents) {
    final l10n = context.l10n;
    final currencies = ref.read(currencyProvider);
    final baseSymbol = ref.read(baseCurrencyProvider).symbol;
    final baseCents = toBaseCents(currencies, cents, _currency);
    final catBudgets = ref.read(categoryBudgetProvider);
    final totalBudget = ref.read(totalBudgetProvider);
    final byCat = ref.read(thisMonthExpenseByCategoryProvider);
    final monthExpense = ref.read(thisMonthExpenseProvider);

    if (_categoryId != null) {
      final budget = catBudgets[_categoryId];
      if (budget != null) {
        final used = byCat[_categoryId] ?? 0;
        final budgetBase = budgetCentsInBase(currencies, budget.amount);
        if (used + baseCents > budgetBase) {
          return l10n.entryOverCategoryBudget(
            MoneyUtil.format(budgetBase, symbol: '$baseSymbol '),
          );
        }
      }
    }
    if (totalBudget != null) {
      final budgetBase = budgetCentsInBase(currencies, totalBudget.amount);
      if (monthExpense + baseCents > budgetBase) {
        return l10n.entryOverTotalBudget(
          MoneyUtil.format(budgetBase, symbol: '$baseSymbol '),
        );
      }
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final text = _amountController.text.trim();
    final cents = MoneyUtil.parseToCents(text);
    if (text.isEmpty) {
      setState(() => _amountError = l10n.entryAmountEmpty);
      return;
    }
    if (cents == null) {
      setState(() => _amountError = l10n.entryAmountInvalid);
      return;
    }
    if (cents <= 0) {
      setState(() => _amountError = l10n.entryAmountPositive);
      return;
    }
    // 与 UI 高亮一致的分类：未选择或原分类已删除时默认取该类型第一个
    final categories = ref.read(categoryProvider);
    final typeCategories = categories
        .where((c) => c.type == _type.index)
        .toList();
    final selectedIds = typeCategories.map((c) => c.key as int).toSet();
    final categoryId = selectedIds.contains(_categoryId)
        ? _categoryId
        : (typeCategories.isEmpty ? null : typeCategories.first.key as int);
    if (!_isEdit && categoryId == null) {
      setState(() => _showCategoryError = true);
      return;
    }

    final note = _noteController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final warning = _overBudgetWarning(cents);

    if (_isEdit) {
      // 编辑需二次确认（已确认规则）
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.entryConfirmEditTitle),
          content: Text(l10n.entryConfirmEditBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.entryConfirmSave),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final t = widget.existing!;
      t.type = _type.index;
      t.amount = cents;
      t.categoryId = categoryId;
      t.date = DateUtil.toDayKey(_date);
      t.note = note.isEmpty ? null : note;
      t.currency = _currency;
      await ref.read(transactionProvider.notifier).update(t);
    } else {
      await ref
          .read(transactionProvider.notifier)
          .add(
            Transaction(
              type: _type.index,
              amount: cents,
              categoryId: categoryId,
              date: DateUtil.toDayKey(_date),
              note: note.isEmpty ? null : note,
              currency: _currency,
              createdAt: DateTime.now(),
            ),
          );
    }
    if (mounted) Navigator.of(context).pop();
    // 超支轻提示（不强制）：关闭面板后在根 Scaffold 上提示
    if (warning != null) {
      messenger.showSnackBar(SnackBar(content: Text(warning)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoryProvider);
    final currencies = ref.watch(currencyProvider);
    final currencySymbol = symbolOf(currencies, _currency);
    final typeCategories = categories
        .where((c) => c.type == _type.index)
        .toList(growable: false);
    // 编辑模式下，若原分类已被删除，保持「未分类」待用户重选
    final selectedIds = typeCategories.map((c) => c.key as int).toSet();
    final effectiveCategoryId = selectedIds.contains(_categoryId)
        ? _categoryId
        : (typeCategories.isEmpty ? null : typeCategories.first.key as int);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _isEdit ? l10n.entryEditTitle : l10n.entryAddTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 第 1 步：类型 + 金额（金额键盘优先，自动聚焦）
                  SegmentedButton<TransactionType>(
                    segments: [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text(l10n.typeExpense),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text(l10n.typeIncome),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => _switchType(s.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      _AmountInputFormatter(
                        onRejected: () {
                          if (_amountError == null) {
                            setState(
                              () => _amountError = l10n.entryAmountTooLong,
                            );
                          }
                        },
                      ),
                    ],
                    onChanged: (_) {
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.commonAmount,
                      prefixText: currencySymbol,
                      errorText: _amountError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 币种（v3.3）：默认当前基准币种，可切换
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(
                      labelText: l10n.commonCurrency,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final c in currencies)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text(
                            '${c.symbol} ${currencyDisplayName(l10n, c)}',
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(
                      () => _currency =
                          v ?? ref.read(baseCurrencyProvider).code,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 第 2 步：分类（默认选中第一个）
                  Text(l10n.commonCategory,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (typeCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.entryAddCategoryFirst),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in typeCategories)
                          ChoiceChip(
                            avatar: Text(
                              c.displayIcon,
                              style: const TextStyle(fontSize: 16),
                            ),
                            label: Text(categoryDisplayName(l10n, c)),
                            selected: c.key == effectiveCategoryId,
                            onSelected: (_) => setState(() {
                              _categoryId = c.key as int;
                              _showCategoryError = false;
                            }),
                          ),
                      ],
                    ),
                  if (_showCategoryError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l10n.entrySelectCategory,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // 日期（默认今天，可修改）
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      '${l10n.commonDate}：${l10n.dateHeader(_date)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  // 备注（可选）
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l10n.recurringNoteOptional,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          // 第 3 步：保存（固定在底部，始终可见）
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(_isEdit ? l10n.entrySaveChanges : l10n.commonSave),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
