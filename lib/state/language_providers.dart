import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';

/// 界面语言偏好：null = 跟随系统；'zh' / 'en' / 'ja' 为手动指定。
/// 持久化在 Hive 的 settings 盒（key: `languageCode`），与外观模式同一套路。
class LanguageNotifier extends Notifier<Locale?> {
  static const String storageKey = 'languageCode';

  @override
  Locale? build() {
    final raw = Db.settings.get(storageKey);
    return switch (raw) {
      'zh' => const Locale('zh'),
      'en' => const Locale('en'),
      'ja' => const Locale('ja'),
      _ => null,
    };
  }

  /// 设置语言并持久化；null 表示跟随系统（删除存储值）。
  Future<void> set(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await Db.settings.delete(storageKey);
    } else {
      await Db.settings.put(storageKey, locale.languageCode);
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, Locale?>(
  LanguageNotifier.new,
);
