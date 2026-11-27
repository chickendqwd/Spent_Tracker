import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/icon_util.dart';
import '../../data/models/category.dart';
import '../../l10n/l10n.dart';
import '../../state/category_providers.dart';

/// 设置 / 分类管理页：预设分类开箱即用，自定义分类可增删改。
/// 已确认规则：预设分类禁止删除；删除自定义分类后历史账目置「未分类」。
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  /// 0=支出，1=收入
  int _tab = 0;

  /// 内置 emoji 候选池（v3.2 扩充）：按「餐饮 / 交通 / 购物 / 居住 / 娱乐 /
  /// 医疗 / 教育 / 收入 / 生活 / 运动」常用类目组织，仍可通过下方输入框自定义。
  static const _iconChoices = [
    // 餐饮
    '🍜', '🍱', '🍔', '🍕', '🍰', '🍎', '☕', '🍺', '🥤', '🥗',
    // 交通
    '🚌', '🚇', '🚗', '🚕', '✈️', '🚲', '⛽', '🅿️', '🛵', '🚄',
    // 购物
    '🛍️', '🛒', '👕', '👟', '💄', '💍', '🎁', '📦', '💳', '🏷️',
    // 居住
    '🏠', '💡', '🛋️', '🧹', '🔧', '🚿', '🪑', '🧺',
    // 娱乐
    '🎮', '🎬', '🎵', '🎤', '🎨', '🎟️', '📺', '🧩',
    // 医疗
    '💊', '🏥', '🩺', '💉', '🦷', '🧴',
    // 教育
    '📚', '✏️', '🎓', '💻', '🖊️', '🔬',
    // 收入
    '💼', '🧧', '📈', '💰', '💵', '🏦',
    // 生活
    '📱', '🐱', '🐶', '🌱', '🧸', '🍼', '🪴', '👶',
    // 运动
    '🏃', '🏋️', '⚽', '🎾', '🏊', '🚴',
    // 其他
    '🔖', '⭐', '✅', '❓',
  ];

  Future<void> _addCategory() async {
    final type = _tab;
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => _CategoryDialog(
        title: context.l10n.categoriesNewTitle,
        type: type,
        iconChoices: _iconChoices,
      ),
    );
    if (result == null || !mounted) return;
    final (name, icon) = result;
    await ref.read(categoryProvider.notifier).add(name, type, icon);
  }

  Future<void> _editCategory(Category category) async {
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => _CategoryDialog(
        title: context.l10n.categoriesEditTitle,
        type: category.type,
        initialName: category.name,
        initialIcon: category.displayIcon,
        iconChoices: _iconChoices,
      ),
    );
    if (result == null || !mounted) return;
    final (name, icon) = result;
    await ref.read(categoryProvider.notifier).update(category, name, icon);
  }

  Future<void> _deleteCategory(Category category) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.categoriesDeleteTitle(
          categoryDisplayName(l10n, category),
        )),
        content: Text(l10n.categoriesDeleteBody),
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
    if (confirmed != true || !mounted) return;
    await ref.read(categoryProvider.notifier).remove(category.key as int);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoryProvider);
    final list = categories.where((c) => c.type == _tab).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, label: Text(l10n.categoriesExpenseTab)),
                ButtonSegment(value: 1, label: Text(l10n.categoriesIncomeTab)),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
              children: [
                for (final c in list)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: Text(
                        c.displayIcon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    title: Text(categoryDisplayName(l10n, c)),
                    subtitle: c.isPreset
                        ? Text(l10n.categoriesPresetLabel)
                        : null,
                    trailing: c.isPreset
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.commonEdit,
                                onPressed: () => _editCategory(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.commonDelete,
                                onPressed: () => _deleteCategory(c),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: Text(
          _tab == 0 ? l10n.categoriesAddExpense : l10n.categoriesAddIncome,
        ),
      ),
    );
  }
}

/// 分类新增/编辑对话框：名称 + 图标选择。
class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    required this.title,
    required this.type,
    required this.iconChoices,
    this.initialName,
    this.initialIcon,
  });

  final String title;
  final int type;
  final List<String> iconChoices;
  final String? initialName;
  final String? initialIcon;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  late String _icon;
  String? _nameError;
  String? _iconError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _iconController = TextEditingController();
    _icon = widget.initialIcon ?? kFallbackCategoryIcon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  /// 自定义图标输入：合法（1–2 个字符）即生效，非法时保留上一个选择并提示。
  void _onCustomIconChanged(String value) {
    final normalized = normalizeCategoryIcon(value);
    setState(() {
      if (normalized != null) {
        _icon = normalized;
        _iconError = null;
      } else if (value.trim().isEmpty) {
        _iconError = null;
      } else {
        _iconError = context.l10n.categoriesCustomIconInvalid;
      }
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.categoriesNameEmpty);
      return;
    }
    Navigator.of(context).pop<(String, String?)>((name, _icon));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.categoriesBelongsTo(l10n.txTypeByIndex(widget.type)),
              style: textTheme.bodySmall?.copyWith(color: context.palette.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.categoriesNameLabel,
                hintText: l10n.categoriesNameHint,
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.categoriesIconLabel, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 132,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final icon in widget.iconChoices)
                      ChoiceChip(
                        avatar: Text(
                          icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        label: const SizedBox.shrink(),
                        selected: _icon == icon,
                        onSelected: (_) {
                          _iconController.clear();
                          setState(() {
                            _icon = icon;
                            _iconError = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _iconController,
              onChanged: _onCustomIconChanged,
              decoration: InputDecoration(
                labelText: l10n.categoriesCustomIconLabel,
                hintText: l10n.categoriesCustomIconHint,
                errorText: _iconError,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  l10n.categoriesCurrent,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
                Text(_icon, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.commonSave)),
      ],
    );
  }
}
