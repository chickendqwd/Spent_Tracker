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
import '../widgets/surfaces.dart';
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
    final palette = context.palette;
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

    final groups = _grouped(filtered);
    final totalExpense = filtered
        .where((t) => t.type == 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final totalIncome = filtered
        .where((t) => t.type == 1)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final baseSymbol = ref.watch(baseCurrencyProvider).symbol;

    return Scaffold(
      appBar: AppBar(title: SectionTitle(l10n.transactionsTitle)),
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.transactionsSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 19),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TimeRangeSelector(),
            ),
            // 筛选栏：类型胶囊 + 分类下拉
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 2),
              child: Row(
                children: [
                  PillChip(
                    label: l10n.transactionsAll,
                    selected: _typeFilter == null,
                    onTap: () => setState(() {
                      _typeFilter = null;
                      _categoryFilter = null;
                    }),
                  ),
                  const SizedBox(width: 6),
                  PillChip(
                    label: l10n.typeExpense,
                    selected: _typeFilter == 0,
                    onTap: () => setState(() {
                      _typeFilter = 0;
                      _categoryFilter = null;
                    }),
                  ),
                  const SizedBox(width: 6),
                  PillChip(
                    label: l10n.typeIncome,
                    selected: _typeFilter == 1,
                    onTap: () => setState(() {
                      _typeFilter = 1;
                      _categoryFilter = null;
                    }),
                  ),
                  const Spacer(),
                  PopupMenuButton<int?>(
                    tooltip: l10n.transactionsAllCategories,
                    initialValue: _categoryFilter,
                    color: palette.card,
                    onSelected: (v) => setState(() => _categoryFilter = v),
                    itemBuilder: (_) => [
                      PopupMenuItem<int?>(
                        value: null,
                        child: Text(l10n.transactionsAllCategories),
                      ),
                      for (final c in filterableCategories)
                        PopupMenuItem<int?>(
                          value: c.key as int,
                          child: Text(
                            '${c.displayIcon} ${categoryDisplayName(l10n, c)}',
                          ),
                        ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categoryFilter == null
                              ? l10n.transactionsAllCategories
                              : categoryDisplayName(
                                  l10n,
                                  categoryByKey[_categoryFilter],
                                ),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _categoryFilter == null
                                ? palette.muted
                                : palette.ink,
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          size: 16,
                          color: palette.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        l10n.transactionsNoMatch,
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                      itemCount: groups.length + 1,
                      itemBuilder: (context, i) {
                        // 首项：区间合计条
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 14,
                                  color: palette.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${filtered.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: palette.primaryDeep,
                                  ),
                                ),
                                const Spacer(),
                                // 只有一条记录时金额已在下方条目里，避免重复展示
                                if (filtered.length > 1) ...[
                                  Text(
                                    '-${MoneyUtil.format(totalExpense, symbol: baseSymbol)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: palette.expense,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '+${MoneyUtil.format(totalIncome, symbol: baseSymbol)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: palette.income,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        final (header, items, dayNet) = groups[i - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                                child: Row(
                                  children: [
                                    Text(
                                      header,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                        color: palette.muted,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    // 单条记录不重复显示当日净额
                                    if (items.length > 1)
                                      Text(
                                        dayNet >= 0
                                            ? '+${MoneyUtil.format(dayNet, symbol: baseSymbol)}'
                                            : '-${MoneyUtil.format(-dayNet, symbol: baseSymbol)}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: dayNet >= 0
                                              ? palette.income
                                              : palette.expense,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SlantCard(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  2,
                                  8,
                                  2,
                                ),
                                child: Column(
                                  children: [
                                    for (final (idx, t) in items.indexed) ...[
                                      TransactionTile(
                                        transaction: t,
                                        category: t.categoryId == null
                                            ? null
                                            : categoryByKey[t.categoryId],
                                        onTap: () =>
                                            TransactionDetailSheet.show(
                                              context,
                                              t,
                                            ),
                                      ),
                                      if (idx != items.length - 1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          child: Container(
                                            height: 1,
                                            color: palette.divider,
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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

  /// 按日期（倒序）分组：返回 [(表头, 账目列表, 当日净额)]
  List<(String, List<Transaction>, int)> _grouped(List<Transaction> list) {
    final l10n = context.l10n;
    final result = <(String, List<Transaction>, int)>[];
    String? currentKey;
    for (final t in list) {
      final delta = t.type == 0 ? -t.amount : t.amount;
      if (t.date != currentKey) {
        currentKey = t.date;
        result.add((
          l10n.dateHeader(DateUtil.fromDayKey(t.date)),
          <Transaction>[t],
          delta,
        ));
      } else {
        final last = result.removeLast();
        result.add((last.$1, [...last.$2, t], last.$3 + delta));
      }
    }
    return result;
  }
}
