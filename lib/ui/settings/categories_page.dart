import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../../data/models/transaction_type.dart';
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

  static const _iconChoices = [
    '🍜',
    '🚌',
    '🛍️',
    '🏠',
    '🎮',
    '💊',
    '📚',
    '💼',
    '🧧',
    '💻',
    '📈',
    '📦',
    '✈️',
    '🎬',
    '☕',
    '🎁',
    '👕',
    '🐱',
    '🏃',
    '📱',
  ];

  Future<void> _addCategory() async {
    final type = _tab;
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) =>
          _CategoryDialog(title: '新增分类', type: type, iconChoices: _iconChoices),
    );
    if (result == null || !mounted) return;
    final (name, icon) = result;
    await ref.read(categoryProvider.notifier).add(name, type, icon);
  }

  Future<void> _editCategory(Category category) async {
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => _CategoryDialog(
        title: '编辑分类',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除分类「${category.name}」？'),
        content: const Text('该分类下的历史账目将变为「未分类」，此操作不可恢复。'),
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
    if (confirmed != true || !mounted) return;
    await ref.read(categoryProvider.notifier).remove(category.key as int);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final list = categories.where((c) => c.type == _tab).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('支出分类')),
                ButtonSegment(value: 1, label: Text('收入分类')),
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
                    title: Text(c.name),
                    subtitle: c.isPreset ? const Text('预设分类') : null,
                    trailing: c.isPreset
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: '编辑',
                                onPressed: () => _editCategory(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: '删除',
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
        label: Text(_tab == 0 ? '新增支出分类' : '新增收入分类'),
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
  late String _icon;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _icon = widget.initialIcon ?? '📦';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '请输入分类名称');
      return;
    }
    Navigator.of(context).pop<(String, String?)>((name, _icon));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '所属类型：${TransactionType.fromIndex(widget.type).label}',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '分类名称',
              hintText: '如：宠物、健身',
              errorText: _nameError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('图标', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final icon in widget.iconChoices)
                ChoiceChip(
                  avatar: Text(icon, style: const TextStyle(fontSize: 18)),
                  label: const SizedBox.shrink(),
                  selected: _icon == icon,
                  onSelected: (_) => setState(() => _icon = icon),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
