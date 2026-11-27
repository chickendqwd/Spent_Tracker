import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../analysis/annual_page.dart';
import 'appearance_page.dart';
import 'budget_settings_page.dart';
import 'categories_page.dart';
import 'currency_page.dart';
import 'export_page.dart';
import 'import_page.dart';
import 'language_page.dart';
import 'recurring_rules_page.dart';

/// 设置主页：语言 + 外观、分类/预算/周期、年报、货币、导入导出。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.settingsGroupGeneral, style: textTheme.labelLarge),
          ),
          _EntryTile(
            icon: Icons.palette_outlined,
            title: l10n.settingsAppearance,
            subtitle: l10n.settingsAppearanceSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearancePage()),
            ),
          ),
          _EntryTile(
            icon: Icons.translate_outlined,
            title: l10n.settingsLanguage,
            subtitle: l10n.settingsLanguageSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LanguagePage()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child:
                Text(l10n.settingsGroupBookkeeping, style: textTheme.labelLarge),
          ),
          _EntryTile(
            icon: Icons.category_outlined,
            title: l10n.settingsCategories,
            subtitle: l10n.settingsCategoriesSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesPage()),
            ),
          ),
          _EntryTile(
            icon: Icons.savings_outlined,
            title: l10n.settingsBudgets,
            subtitle: l10n.settingsBudgetsSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BudgetSettingsPage()),
            ),
          ),
          _EntryTile(
            icon: Icons.event_repeat_outlined,
            title: l10n.settingsRecurring,
            subtitle: l10n.settingsRecurringSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringRulesPage()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.settingsGroupAnalysis, style: textTheme.labelLarge),
          ),
          _EntryTile(
            icon: Icons.insights_outlined,
            title: l10n.settingsAnnual,
            subtitle: l10n.settingsAnnualSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnualPage()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.settingsGroupData, style: textTheme.labelLarge),
          ),
          _EntryTile(
            icon: Icons.currency_exchange,
            title: l10n.settingsCurrency,
            subtitle: l10n.settingsCurrencySubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CurrencyPage()),
            ),
          ),
          _EntryTile(
            icon: Icons.ios_share,
            title: l10n.settingsExport,
            subtitle: l10n.settingsExportSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExportPage()),
            ),
          ),
          _EntryTile(
            icon: Icons.file_download_outlined,
            title: l10n.settingsImport,
            subtitle: l10n.settingsImportSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportPage()),
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
