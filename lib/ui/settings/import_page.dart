import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/io/import_parser.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/import_service.dart';

/// 数据导入页（v3）：选择 CSV / JSON 备份 → 预览（可导入/重复/失败）
/// → 用户确认后追加写入，分类按名称映射，找不到的落为「未分类」。
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  ImportParseResult? _parsed;
  ImportDryRun? _dryRun;
  String? _fileName;
  bool _busy = false;
  bool _done = false;

  Future<void> _pickFile() async {
    setState(() => _busy = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'json'],
      );
      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _toast('该文件为空');
        return;
      }

      final parsed = parseImportContent(
        utf8.decode(bytes, allowMalformed: true),
        fileName: file.name,
      );
      final dryRun = const ImportService().preview(parsed.candidates);

      setState(() {
        _fileName = file.name;
        _parsed = parsed;
        _dryRun = dryRun;
        _done = false;
      });
    } on FormatException catch (e) {
      _toast(e.message);
      setState(() {
        _parsed = null;
        _dryRun = null;
      });
    } catch (e) {
      _toast('读取失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commit() async {
    final dryRun = _dryRun;
    if (dryRun == null || dryRun.toImport.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认导入？'),
        content: Text(
          '将追加 ${dryRun.toImport.length} 笔账目；'
          '跳过重复 ${dryRun.duplicates} 笔。'
          '导入不会删除或覆盖现有记录。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final outcome = await const ImportService().commit(dryRun);
      if (!mounted) return;
      setState(() {
        _done = true;
        _parsed = null;
        _dryRun = null;
      });
      _toast(
        '已导入 ${outcome.imported} 笔'
        '${outcome.duplicates > 0 ? '，跳过重复 ${outcome.duplicates} 笔' : ''}'
        '${outcome.unmatchedCategories > 0 ? '，${outcome.unmatchedCategories} 笔分类未匹配已记为未分类' : ''}',
      );
    } catch (e) {
      _toast('导入失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final parsed = _parsed;
    final dryRun = _dryRun;

    return Scaffold(
      appBar: AppBar(title: const Text('数据导入')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('从备份文件恢复', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    '支持本应用导出的 CSV / JSON。导入为「追加」：'
                    '不会删除或覆盖现有账目；同类型、同金额、同币种、同日期、'
                    '同备注、同分类的记录会被视为重复并跳过。',
                    style: textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('选择 CSV / JSON 文件'),
                      onPressed: _busy ? null : _pickFile,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (parsed != null && dryRun != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? '已选择文件',
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '可导入',
                      value: '${dryRun.toImport.length} 笔',
                      emphasized: true,
                    ),
                    _StatRow(
                      label: '重复跳过',
                      value: '${dryRun.duplicates} 笔',
                    ),
                    _StatRow(
                      label: '格式失败',
                      value: '${parsed.issues.length} 笔',
                      bad: parsed.issues.isNotEmpty,
                    ),
                    _StatRow(
                      label: '分类未匹配（将记为未分类）',
                      value: '${dryRun.unmatchedCategories} 笔',
                    ),
                    const SizedBox(height: 12),
                    if (parsed.issues.isNotEmpty) ...[
                      Text(
                        '失败明细（最多显示 5 条）',
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      const SizedBox(height: 4),
                      for (final issue in parsed.issues.take(5))
                        Text(
                          '第 ${issue.rowNumber} 行：${issue.reason}',
                          style: textTheme.bodySmall
                              ?.copyWith(color: context.palette.expense),
                        ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            dryRun.toImport.isEmpty || _busy ? null : _commit,
                        child: Text(
                          dryRun.toImport.isEmpty
                              ? '没有可导入的新记录'
                              : '确认导入 ${dryRun.toImport.length} 笔',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_done) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text('导入完成，明细与总览已刷新', style: textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            '提示：先在「数据导出」里导出一份当前数据，再导入旧备份，'
            '可最大程度避免误操作带来的数据混乱。',
            style: textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.bad = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = bad
        ? context.palette.expense
        : (emphasized ? context.palette.income : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: context.palette.muted),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
