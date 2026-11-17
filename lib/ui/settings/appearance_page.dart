import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_providers.dart';

/// 外观设置：跟随系统 / 浅色 / 深色，选择即时生效并持久化。
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('外观')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final option in const [
            (
              mode: ThemeMode.system,
              icon: Icons.brightness_auto_outlined,
              title: '跟随系统',
              subtitle: '随手机/电脑的深浅色设置自动切换',
            ),
            (
              mode: ThemeMode.light,
              icon: Icons.light_mode_outlined,
              title: '浅色',
              subtitle: '始终使用浅色主题',
            ),
            (
              mode: ThemeMode.dark,
              icon: Icons.dark_mode_outlined,
              title: '深色',
              subtitle: '始终使用深色主题',
            ),
          ])
            ListTile(
              leading: Icon(option.icon),
              title: Text(option.title),
              subtitle: Text(option.subtitle),
              trailing: current == option.mode
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(Icons.circle_outlined),
              selected: current == option.mode,
              onTap: () => notifier.set(option.mode),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '深色模式下的图表、金额颜色会自动适配背景亮度。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
