import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_schemes.dart';
import '../data/db/database.dart';

/// 外观模式（跟随系统 / 浅色 / 深色），持久化在 Hive 的 settings 盒。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String storageKey = 'themeMode';

  @override
  ThemeMode build() {
    final raw = Db.settings.get(storageKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// 切换外观并持久化；写入失败不影响本次会话生效。
  Future<void> set(ThemeMode mode) async {
    state = mode;
    await Db.settings.put(storageKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// 配色方案（10 套三色配色，默认黑白灰），持久化在 settings 盒。
class PaletteSchemeNotifier extends Notifier<AppPaletteScheme> {
  static const String storageKey = 'paletteScheme';

  @override
  AppPaletteScheme build() =>
      AppPaletteSchemes.byId(Db.settings.get(storageKey));

  /// 切换配色并持久化；写入失败不影响本次会话生效。
  Future<void> set(AppPaletteScheme scheme) async {
    state = scheme;
    await Db.settings.put(storageKey, scheme.id);
  }

  /// 换回默认黑白灰。
  Future<void> reset() => set(AppPaletteSchemes.gray);
}

final paletteSchemeProvider =
    NotifierProvider<PaletteSchemeNotifier, AppPaletteScheme>(
  PaletteSchemeNotifier.new,
);

