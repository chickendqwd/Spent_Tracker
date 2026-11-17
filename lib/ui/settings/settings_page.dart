import 'package:flutter/material.dart';

import 'appearance_page.dart';
import 'budget_settings_page.dart';
import 'categories_page.dart';
import 'currency_page.dart';
import 'export_page.dart';
import 'recurring_rules_page.dart';

/// 设置主页（v2）：分类管理 + 预算设置 + 周期记账 + 货币与汇率 + 数据导出。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('通用', style: textTheme.labelLarge),
          ),
          _EntryTile(
            icon: Icons.palette_outlined,
            title: '外观',
            subtitle: '跟随系统 / 浅色 / 深色',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearancePage()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('记账管理', style: textTheme.labelLarge),
          ),
          _EntryTile(
            icon: Icons.category_outlined,
            title: '分类管理',
            subtitle: '预设 + 自定义分类',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesPage()),
            ),
          ),
          _EntryTile(
            icon: Icons.savings_outlined,
            title: '预算设置',
            subtitle: '月度总预算与分类预算',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BudgetSettingsPage()),
            ),
          ),
          _EntryTile(
            icon: Icons.event_repeat_outlined,
            title: '周期记账',
            subtitle: '每周 / 每月 / 每年待记提醒',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringRulesPage()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('数据', style: textTheme.labelLarge),
          ),
          _EntryTile(
            icon: Icons.currency_exchange,
            title: '货币与汇率',
            subtitle: '基准 SGD，可手动或联网更新',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CurrencyPage()),
            ),
          ),
          _EntryTile(
            icon: Icons.ios_share,
            title: '数据导出',
            subtitle: '导出 CSV / JSON 备份',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExportPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
