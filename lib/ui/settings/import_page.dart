import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/io/encoding_util.dart';
import '../../core/io/import_parser.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/import_service.dart';
import '../../l10n/l10n.dart';

/// 数据导入页（v3）：选择 CSV / JSON 备份 → 预览（可导入/重复/失败）
/// → 用户确认后追加写入，分类按中性标识或名称映射，找不到的落为「未分类」。
///
/// v3.4：读取字节后按 UTF-8 / UTF-16 / GBK 自动识别编码（B7）；
/// 解析错误改为结构化错误码，文案随界面语言（R5）。
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
    final l10n = context.l10n;
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
        _toast(l10n.importEmptyFile);
        return;
      }

      final parsed = parseImportContent(
        ImportTextDecoder.decode(bytes),
        fileName: file.name,
      );
      final dryRun = const ImportService().preview(parsed.candidates);

      setState(() {
        _fileName = file.name;
        _parsed = parsed;
        _dryRun = dryRun;
        _done = false;
      });
    } on ImportException catch (e) {
      _toast(importErrorText(l10n, e));
      setState(() {
        _parsed = null;
        _dryRun = null;
      });
    } catch (e) {
      _toast(l10n.importReadFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commit() async {
    final l10n = context.l10n;
    final dryRun = _dryRun;
    if (dryRun == null || dryRun.toImport.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(
          l10n.importConfirmBody('${dryRun.toImport.length}', '${dryRun.duplicates}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.importAction),
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
        l10n.importDoneCount('${outcome.imported}') +
            (outcome.duplicates > 0
                ? l10n.importSkipped('${outcome.duplicates}')
                : '') +
            (outcome.unmatchedCategories > 0
                ? l10n.importUnmatchedSuffix('${outcome.unmatchedCategories}')
                : ''),
      );
    } catch (e) {
      _toast(l10n.importFailed('$e'));
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
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final parsed = _parsed;
    final dryRun = _dryRun;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.importRestore, style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    l10n.importIntro,
                    style: textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(l10n.importChooseFile),
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
                      _fileName ?? l10n.importSelectedFile,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: l10n.importImportable,
                      value: l10n.commonUnitEntries('${dryRun.toImport.length}'),
                      emphasized: true,
                    ),
                    _StatRow(
                      label: l10n.importSkippedDuplicates,
                      value: l10n.commonUnitEntries('${dryRun.duplicates}'),
                    ),
                    _StatRow(
                      label: l10n.importParseFailed,
                      value: l10n.commonUnitEntries('${parsed.issues.length}'),
                      bad: parsed.issues.isNotEmpty,
                    ),
                    _StatRow(
                      label: l10n.importUnmatched,
                      value: l10n.commonUnitEntries(
                        '${dryRun.unmatchedCategories}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (parsed.issues.isNotEmpty) ...[
                      Text(
                        l10n.importFailureDetails,
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      const SizedBox(height: 4),
                      for (final issue in parsed.issues.take(5))
                        Text(
                          l10n.importRowIssue(
                            '${issue.rowNumber}',
                            importIssueText(l10n, issue),
                          ),
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
                              ? l10n.importNoNewRecords
                              : l10n.importConfirmCount(
                                  '${dryRun.toImport.length}',
                                ),
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
                    Expanded(
                      child: Text(
                        l10n.importSuccess,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.importTip,
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
