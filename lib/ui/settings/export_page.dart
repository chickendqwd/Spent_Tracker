import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/money_util.dart';
import '../../state/category_providers.dart';
import '../../state/transaction_providers.dart';

/// 数据导出页（v2）：CSV / JSON 备份，经系统分享面板保存。
/// 内容为全部账目；金额以「元」两位小数导出便于查看。
class ExportPage extends ConsumerWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txCount = ref.watch(transactionProvider).length;
    return Scaffold(
      appBar: AppBar(title: const Text('数据导出')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '共 $txCount 笔账目',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '导出为 CSV 或 JSON 备份文件，可保存到「下载」或发送。'
                    '导出的文件可在「数据导入」中恢复。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('导出 CSV'),
                          onPressed: () => _export(context, ref, 'csv'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.data_object),
                          label: const Text('导出 JSON'),
                          onPressed: () => _export(context, ref, 'json'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String format) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!context.mounted) return;

    try {
      final transactions = ref.read(transactionProvider);
      final categories = ref.read(categoryProvider);
      final categoryByKey = {for (final c in categories) c.key as int: c};

      final rows = <Map<String, dynamic>>[
        for (final t in transactions)
          {
            'id': t.key,
            'type': t.transactionType.label,
            'amount': MoneyUtil.inputText(t.amount),
            'currency': t.currency,
            'category': t.categoryId == null
                ? '未分类'
                : (categoryByKey[t.categoryId]?.name ?? '未分类'),
            'date': t.date,
            'note': t.note ?? '',
            'createdAt': t.createdAt.toIso8601String(),
          },
      ];

      final now = DateTime.now();
      final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final dir = await getTemporaryDirectory();
      final ext = format == 'csv' ? 'csv' : 'json';
      final file = File(
        '${dir.path}${Platform.pathSeparator}spent_tracker_export_$stamp.$ext',
      );

      final content = format == 'csv' ? _toCsv(rows) : JsonEncoder.withIndent('  ').convert(rows);
      await file.writeAsString(content, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: format == 'csv' ? 'text/csv' : 'application/json')],
          fileNameOverrides: ['spent_tracker_export_$stamp.$ext'],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }

  String _toCsv(List<Map<String, dynamic>> rows) {
    const header = 'id,type,amount,currency,category,date,note,createdAt';
    final lines = <String>[header];
    for (final r in rows) {
      lines.add([
        _csvEscape(r['id']),
        _csvEscape(r['type']),
        _csvEscape(r['amount']),
        _csvEscape(r['currency']),
        _csvEscape(r['category']),
        _csvEscape(r['date']),
        _csvEscape(r['note']),
        _csvEscape(r['createdAt']),
      ].join(','));
    }
    return lines.join('\n');
  }

  /// CSV 字段转义：含逗号/引号/换行时用双引号包裹并转义内部引号。
  String _csvEscape(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
