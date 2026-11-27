import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/theme_providers.dart';

/// 外观设置：跟随系统 / 浅色 / 深色，选择即时生效并持久化。
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    final options = <(ThemeMode, IconData, String, String)>[
      (
        ThemeMode.system,
        Icons.brightness_auto_outlined,
        l10n.appearanceThemeSystem,
        l10n.appearanceThemeSystemSub,
      ),
      (
        ThemeMode.light,
        Icons.light_mode_outlined,
        l10n.appearanceThemeLight,
        l10n.appearanceThemeLightSub,
      ),
      (
        ThemeMode.dark,
        Icons.dark_mode_outlined,
        l10n.appearanceThemeDark,
        l10n.appearanceThemeDarkSub,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearanceTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final option in options)
            ListTile(
              leading: Icon(option.$2),
              title: Text(option.$3),
              subtitle: Text(option.$4),
              trailing: current == option.$1
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(Icons.circle_outlined),
              selected: current == option.$1,
              onTap: () => notifier.set(option.$1),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.appearanceNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
