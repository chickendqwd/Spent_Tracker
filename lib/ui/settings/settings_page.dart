import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../analysis/annual_page.dart';
import '../widgets/surfaces.dart';
import 'appearance_page.dart';
import 'budget_settings_page.dart';
import 'categories_page.dart';
import 'currency_page.dart';
import 'export_page.dart';
import 'import_page.dart';
import 'language_page.dart';
import 'palette_page.dart';
import 'recurring_rules_page.dart';

/// 设置主页：语言 + 外观、分类/预算/周期、年报、货币、导入导出。
/// 分组标题 + 斜切角卡片承载条目，保持与总览页同一套视觉语言。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: SectionTitle(l10n.settingsTitle)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            _Group(
              label: l10n.settingsGroupGeneral,
              entries: [
                _Entry(
                  icon: Icons.format_paint_outlined,
                  title: l10n.settingsPalette,
                  subtitle: l10n.settingsPaletteSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PalettePage()),
                  ),
                ),
                _Entry(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsAppearance,
                  subtitle: l10n.settingsAppearanceSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppearancePage()),
                  ),
                ),
                _Entry(
                  icon: Icons.translate_outlined,
                  title: l10n.settingsLanguage,
                  subtitle: l10n.settingsLanguageSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguagePage()),
                  ),
                ),
              ],
            ),
            _Group(
              label: l10n.settingsGroupBookkeeping,
              entries: [
                _Entry(
                  icon: Icons.category_outlined,
                  title: l10n.settingsCategories,
                  subtitle: l10n.settingsCategoriesSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesPage()),
                  ),
                ),
                _Entry(
                  icon: Icons.savings_outlined,
                  title: l10n.settingsBudgets,
                  subtitle: l10n.settingsBudgetsSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BudgetSettingsPage(),
                    ),
                  ),
                ),
                _Entry(
                  icon: Icons.event_repeat_outlined,
                  title: l10n.settingsRecurring,
                  subtitle: l10n.settingsRecurringSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecurringRulesPage(),
                    ),
                  ),
                ),
              ],
            ),
            _Group(
              label: l10n.settingsGroupAnalysis,
              entries: [
                _Entry(
                  icon: Icons.insights_outlined,
                  title: l10n.settingsAnnual,
                  subtitle: l10n.settingsAnnualSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnnualPage()),
                  ),
                ),
              ],
            ),
            _Group(
              label: l10n.settingsGroupData,
              entries: [
                _Entry(
                  icon: Icons.currency_exchange,
                  title: l10n.settingsCurrency,
                  subtitle: l10n.settingsCurrencySubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CurrencyPage()),
                  ),
                ),
                _Entry(
                  icon: Icons.ios_share,
                  title: l10n.settingsExport,
                  subtitle: l10n.settingsExportSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExportPage()),
                  ),
                ),
                _Entry(
                  icon: Icons.file_download_outlined,
                  title: l10n.settingsImport,
                  subtitle: l10n.settingsImportSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ImportPage()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 一个设置分组：小标签 + 卡片内条目列表（条目之间用细线分隔）。
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.entries});

  final String label;
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 11,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          SlantCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (i, e) in entries.indexed) ...[
                  e,
                  if (i != entries.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 60, right: 14),
                      child: Container(height: 1, color: palette.divider),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 条目：浅色方形图标 + 标题/说明 + 右箭头。
class _Entry extends StatelessWidget {
  const _Entry({
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
    final palette = context.palette;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 2, 10, 2),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.cardTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: palette.primaryDeep),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, color: palette.muted),
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: palette.muted),
      onTap: onTap,
    );
  }
}
