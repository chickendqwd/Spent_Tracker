import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/currency.dart';
import '../../state/currency_providers.dart';

/// 货币与汇率页（v2）：基准 SGD，手动编辑为主，可选联网更新一次。
/// 汇总数字统一以 SGD 显示；列表/详情保留原记账币种。
class CurrencyPage extends ConsumerWidget {
  const CurrencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('货币与汇率')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '基准币种：SGD。所有汇总（结余、趋势、预算、分类占比）统一以 SGD 显示。'
            '汇率为「1 单位本币 = ? SGD」。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final c in currencies) _CurrencyTile(currency: c),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('联网更新汇率'),
            onPressed: () => _refreshRates(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRates(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final rates = await _fetchRates();
      if (rates.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('联网失败，已保留手动汇率')),
        );
        return;
      }
      await ref.read(currencyProvider.notifier).updateRates(rates);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('已更新：${rates.entries.map((e) => '${e.key} ${e.value.toStringAsFixed(4)}').join('，')}')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('联网失败，已保留手动汇率：$e')),
      );
    }
  }

  /// 从免费汇率 API 拉取「1 SGD = ? 本币」，换算为「1 本币 = ? SGD」。
  Future<Map<String, double>> _fetchRates() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(
        Uri.parse('https://open.er-api.com/v6/latest/SGD'),
      );
      final resp = await req.close();
      if (resp.statusCode != 200) return const {};
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final rates = (json['rates'] as Map<String, dynamic>?) ?? const {};
      final result = <String, double>{};
      for (final code in ['CNY', 'MYR']) {
        final perSgd = rates[code];
        if (perSgd is num && perSgd > 0) {
          result[code] = 1.0 / perSgd.toDouble();
        }
      }
      return result;
    } finally {
      client.close();
    }
  }
}

class _CurrencyTile extends ConsumerWidget {
  const _CurrencyTile({required this.currency});

  final Currency currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBase = currency.isBase == true;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(currency.symbol, style: const TextStyle(fontSize: 16)),
        ),
        title: Text('${currency.name} (${currency.code})'),
        subtitle: Text(
          isBase
              ? '基准币种'
              : '1 ${currency.code} = ${currency.rateToSgd.toStringAsFixed(4)} SGD',
        ),
        trailing: isBase
            ? Icon(Icons.star, color: context.palette.accent)
            : IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '修改汇率',
                onPressed: () => _editRate(context, ref),
              ),
      ),
    );
  }

  Future<void> _editRate(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: currency.rateToSgd.toStringAsFixed(4),
    );
    final messenger = ScaffoldMessenger.of(context);
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改 ${currency.code} 汇率'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: '1 本币 = ? SGD',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v == null || v <= 0) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('请输入正数汇率')),
                );
                return;
              }
              Navigator.of(ctx).pop(v);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (value == null) return;
    await ref.read(currencyProvider.notifier).updateRate(
          currency.code,
          value,
        );
  }
}
