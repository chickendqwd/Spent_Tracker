import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/language_providers.dart';

/// 语言设置：跟随系统 / 中文 / English / 日本語，选择即时生效并持久化。
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(languageProvider);
    final notifier = ref.read(languageProvider.notifier);

    final options = <(Locale?, IconData, String, String)>[
      (
        null,
        Icons.language_outlined,
        l10n.languageFollowSystem,
        l10n.languageSystemSub,
      ),
      (
        const Locale('zh'),
        Icons.translate_outlined,
        l10n.languageChinese,
        '简体中文',
      ),
      (
        const Locale('en'),
        Icons.translate_outlined,
        l10n.languageEnglish,
        'English',
      ),
      (
        const Locale('ja'),
        Icons.translate_outlined,
        l10n.languageJapanese,
        '日本語',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final option in options)
            ListTile(
              leading: Icon(option.$2),
              title: Text(option.$3),
              subtitle: Text(option.$4),
              trailing: current?.languageCode == option.$1?.languageCode
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(Icons.circle_outlined),
              selected: current?.languageCode == option.$1?.languageCode,
              onTap: () => notifier.set(option.$1),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.languageNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
