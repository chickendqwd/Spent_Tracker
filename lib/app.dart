import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme/app_schemes.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'state/language_providers.dart';
import 'state/theme_providers.dart';
import 'ui/app_shell.dart';

/// 应用根组件：主题随系统或用户在「外观」中的选择切换；
/// 语言默认跟随系统，也可在「语言」页手动指定中 / 英 / 日。
class SpentTrackerApp extends ConsumerWidget {
  const SpentTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scheme = ref.watch(paletteSchemeProvider);
    final locale = ref.watch(languageProvider);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // null 表示跟随系统；指定时MaterialApp 会按 locale 选择 ARB 文案
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightWith(buildLightPalette(scheme)),
      darkTheme: AppTheme.darkWith(buildDarkPalette(scheme)),
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
