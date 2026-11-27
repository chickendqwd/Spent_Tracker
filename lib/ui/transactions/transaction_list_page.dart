import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/money_util.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/transaction.dart';
import '../../l10n/l10n.dart';
import '../../state/category_providers.dart';
import '../../state/currency_providers.dart';
import '../../state/transaction_providers.dart';
import '../../state/time_range_providers.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/time_range_selector.dart';

/// 交易列表页：时间倒序、类型/分类筛选、时间范围切换、搜索、点击查看/编辑/删除。
class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  /// null=全部，0=支出，1=收入
  int? _typeFilter;

  /// null=全部分类
  int? _categoryFilter;

  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final currencies = ref.watch(currencyProvider);
    final range = ref.watch(dateRangeProvider);
    final categoryByKey = {for (final c in categories) c.key as int: c};

    // 分类筛选下拉的候选项：跟随类型筛选
    final filterableCategories = categories
        .where((c) => _typeFilter == null || c.type == _typeFilter)
        .toList();
    final filterIds = filterableCategories.map((c) => c.key as int).toSet();
    if (_categoryFilter != null && !filterIds.contains(_categoryFilter)) {
      // 类型切换后清空失效的分类筛选
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _categoryFilter = null);
      });
    }

    final query = _query.trim();
    final queryCents = MoneyUtil.parseToCents(query);
    final filtered = transactions
        .where((t) {
          if (!range.containsKey(t.date)) return false;
          if (_typeFilter != null && t.type != _typeFilter) return false;
          if (_categoryFilter != null && t.categoryId != _categoryFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          return _matches(
            t,
            query: query,
            queryCents: queryCents,
            categoryByKey: categoryByKey,
            currencies: currencies,
            l10n: l10n,
          );
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.transactionsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TimeRangeSelector(),
          ),
          // 筛选栏：类型 + 分类
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                SegmentedButton<int?>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: [
                    ButtonSegment(value: null, label: Text(l10n.transactionsAll)),
                    ButtonSegment(value: 0, label: Text(l10n.typeExpense)),
                    ButtonSegment(value: 1, label: Text(l10n.typeIncome)),
                  ],
                  selected: {_typeFilter},
                  onSelectionChanged: (s) => setState(() {
                    _typeFilter = s.first;
                    _categoryFilter = null;
                  }),
                ),
                const Spacer(),
                DropdownButton<int?>(
                  value: _categoryFilter,
                  hint: Text(l10n.transactionsAllCategories),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.transactionsAllCategories),
                    ),
                    for (final c in filterableCategories)
                      DropdownMenuItem<int?>(
                        value: c.key as int,
                        child: Text(
                          '${c.displayIcon} ${categoryDisplayName(l10n, c)}',
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 列表：按日期分组
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.transactionsNoMatch))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: _grouped(filtered).length,
                    itemBuilder: (context, i) {
                      final (header, items) = _grouped(filtered)[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              header,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: context.palette.muted),
                            ),
                          ),
                          for (final t in items)
                            TransactionTile(
                              transaction: t,
                              category: t.categoryId == null
                                  ? null
                                  : categoryByKey[t.categoryId],
                              onTap: () =>
                                  TransactionDetailSheet.show(context, t),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 搜索口径（v3.4 B6）：备注、分类展示名、金额显示值、币种代码与符号
  /// 一律按「包含」匹配（大小写不敏感）；输入能解析为金额时额外做金额精确匹配。
  /// 分类展示名用当前语言，因此英文界面搜「Food」也能命中预设分类。
  bool _matches(
    Transaction t, {
    required String query,
    required int? queryCents,
    required Map<int, Category> categoryByKey,
    required List<Currency> currencies,
    required AppLocalizations l10n,
  }) {
    final q = query.toLowerCase();
    final note = (t.note ?? '').toLowerCase();
    final categoryText = categoryDisplayName(
      l10n,
      t.categoryId == null ? null : categoryByKey[t.categoryId],
    ).toLowerCase();
    final amountText = MoneyUtil.inputText(t.amount);
    final symbolText = symbolOf(currencies, t.currency).toLowerCase();
    final codeText = t.currency.toLowerCase();

    return note.contains(q) ||
        categoryText.contains(q) ||
        amountText.contains(q) ||
        symbolText.contains(q) ||
        codeText.contains(q) ||
        (queryCents != null && t.amount == queryCents);
  }

  /// 按日期（倒序）分组：返回 [(表头, 账目列表)]
  List<(String, List<Transaction>)> _grouped(List<Transaction> list) {
    final l10n = context.l10n;
    final result = <(String, List<Transaction>)>[];
    String? currentKey;
    List<Transaction>? currentItems;
    for (final t in list) {
      if (t.date != currentKey) {
        currentKey = t.date;
        currentItems = [];
        result.add((
          l10n.dateHeader(DateUtil.fromDayKey(t.date)),
          currentItems,
        ));
      }
      currentItems!.add(t);
    }
    return result;
  }
}
