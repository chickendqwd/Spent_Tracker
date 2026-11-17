import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
