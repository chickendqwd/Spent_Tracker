import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/currency.dart';
import '../../state/currency_providers.dart';

/// 货币与汇率页（v3.3）：基准币种可切换，手动编辑为主，可选联网更新一次。
/// 汇总数字统一以当前基准币种显示；列表/详情保留原记账币种。
///
/// 汇率存储口径不变：`rateToSgd` 始终是「1 单位本币 = ? SGD」，SGD 为换算锚点。
/// 页面展示与编辑用「1 单位本币 = ? 基准币种」，两者在这里互相换算。
class CurrencyPage extends ConsumerWidget {
  const CurrencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currencyProvider);
    final base = ref.watch(baseCurrencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('货币与汇率')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '当前基准币种：${base.name}（${base.code}）。所有汇总（结余、趋势、预算、分类占比）'
            '按基准币种显示；明细与详情保留每笔账目自己的币种。'
            '汇率为「1 单位本币 = ? ${base.code}」，可手动修改或联网更新。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final c in currencies)
            _CurrencyTile(currency: c, base: base, currencies: currencies),
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
      final missing = _remoteCodes.where((c) => !rates.containsKey(c)).toList();
      if (rates.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('联网失败，已保留手动汇率')),
        );
        return;
      }
      await ref.read(currencyProvider.notifier).updateRates(rates);
      if (context.mounted) {
        final updated =
            rates.entries.map((e) => '${e.key} ${e.value.toStringAsFixed(5)}');
        final tail = missing.isEmpty
            ? ''
            : '；未获取到 ${missing.join('、')}，沿用本地汇率';
        messenger.showSnackBar(
          SnackBar(content: Text('已更新：${updated.join('，')}$tail')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('联网失败，已保留手动汇率：$e')),
      );
    }
  }

  /// 需要联网更新的币种（除 SGD 锚点外全部预设）。
  static const List<String> _remoteCodes = ['CNY', 'MYR', 'JPY'];

  /// 从免费汇率 API 拉取「1 SGD = ? 本币」，换算为「1 本币 = ? SGD」。
  /// 单独某个币种缺失时不写入该币种，由调用方提示「沿用本地汇率」。
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
      for (final code in _remoteCodes) {
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
  const _CurrencyTile({
    required this.currency,
    required this.base,
    required this.currencies,
  });

  final Currency currency;
  final Currency base;
  final List<Currency> currencies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBase = currency.code == base.code;
    // 相对基准的汇率：1 本币 = ? 基准
    final perBase = rateToBaseOf(currencies, currency.code);
    final decimals = perBase >= 1 ? 4 : 5;

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
              : '1 ${currency.code} = ${perBase.toStringAsFixed(decimals)} ${base.code}',
        ),
        trailing: isBase
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: context.palette.accent, size: 18),
                  const SizedBox(width: 4),
                  Text('基准', style: Theme.of(context).textTheme.bodySmall),
                ],
              )
            : PopupMenuButton<String>(
                tooltip: '更多操作',
                onSelected: (v) {
                  if (v == 'rate') {
                    _editRate(context, ref);
                  } else if (v == 'base') {
                    _confirmSetBase(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  // SGD 是换算锚点，其汇率恒为 1，不提供编辑入口
                  if (currency.code != 'SGD')
                    const PopupMenuItem(
                      value: 'rate',
                      child: Text('修改汇率'),
                    ),
                  const PopupMenuItem(
                    value: 'base',
                    child: Text('设为基准币种'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmSetBase(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('把 ${currency.code} 设为基准币种？'),
        content: Text(
          '汇总（结余、趋势、预算、分类占比）将改为按 ${currency.name} 显示。\n'
          '历史账目与已录预算的存储金额不会改写，只是换算后展示；'
          '明细仍显示每笔账目自己的币种。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('切换'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(currencyProvider.notifier).setBase(currency.code);
  }

  Future<void> _editRate(BuildContext context, WidgetRef ref) async {
    final baseRate = baseRateOf(currencies);
    // 展示值 = 相对基准；保存值 = 写入 Hive 的「对 SGD」汇率
    final perBase = rateToBaseOf(currencies, currency.code);
    final controller = TextEditingController(
      text: perBase.toStringAsFixed(perBase >= 1 ? 4 : 5),
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
          decoration: InputDecoration(
            labelText: '1 ${currency.code} = ? ${base.code}',
            border: const OutlineInputBorder(),
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
    // 转回对 SGD 的存储口径：rateToSgd = 相对基准值 × 基准自身对 SGD 汇率
    final baseRateSafe = baseRate <= 0 ? 1.0 : baseRate;
    await ref.read(currencyProvider.notifier).updateRate(
          currency.code,
          value * baseRateSafe,
        );
  }
}
