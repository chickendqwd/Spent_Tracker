import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
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
class _AmountInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d{0,7}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
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
    // 币种：编辑/预填沿用其币种；新增默认基准币种（SGD）
    _currency = seed?.currency ?? 'SGD';
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
    final currencies = ref.read(currencyProvider);
    final sgdCents = toBaseCents(currencies, cents, _currency);
    final catBudgets = ref.read(categoryBudgetProvider);
    final totalBudget = ref.read(totalBudgetProvider);
    final byCat = ref.read(thisMonthExpenseByCategoryProvider);
    final monthExpense = ref.read(thisMonthExpenseProvider);

    if (_categoryId != null) {
      final budget = catBudgets[_categoryId];
      if (budget != null) {
        final used = byCat[_categoryId] ?? 0;
        if (used + sgdCents > budget.amount) {
          return '本月该分类将超出预算（${MoneyUtil.format(budget.amount, symbol: 'S\$ ')}）';
        }
      }
    }
    if (totalBudget != null && monthExpense + sgdCents > totalBudget.amount) {
      return '本月总支出将超出预算（${MoneyUtil.format(totalBudget.amount, symbol: 'S\$ ')}）';
    }
    return null;
  }

  Future<void> _save() async {
    final cents = MoneyUtil.parseToCents(_amountController.text);
    if (cents == null || cents <= 0) {
      setState(() => _amountError = '请输入有效金额');
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
          title: const Text('确认保存修改？'),
          content: const Text('保存后将覆盖原有记录。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确认保存'),
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
                        _isEdit ? '编辑账目' : '记一笔',
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
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('支出'),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('收入'),
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
                    inputFormatters: [_AmountInputFormatter()],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: '金额',
                      prefixText: currencySymbol,
                      errorText: _amountError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 币种（v2）：默认基准 SGD，可切换
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: '币种',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final c in currencies)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.symbol} ${c.name}'),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _currency = v ?? 'SGD'),
                  ),
                  const SizedBox(height: 20),
                  // 第 2 步：分类（默认选中第一个）
                  Text('分类', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (typeCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('请先在「设置 → 分类管理」中添加该类型分类'),
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
                            label: Text(c.name),
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
                        '请选择分类',
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
                    title: Text('日期：${DateUtil.listHeader(_date)}'),
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
                    decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      border: OutlineInputBorder(),
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
                child: Text(_isEdit ? '保存修改' : '保存'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
