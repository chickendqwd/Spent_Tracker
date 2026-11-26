import 'package:flutter/material.dart';

/// 全局常量（v1 固定配置，按 agent.md 确认）。
class AppConstants {
  AppConstants._();

  static const String appName = 'Spent_Tracker';

  /// 支出金额列表前缀
  static const String expensePrefix = '-';

  /// 收入金额列表前缀
  static const String incomePrefix = '+';

  /// 支出展示色
  static const Color expenseColor = Color(0xFFE5484D);

  /// 收入展示色
  static const Color incomeColor = Color(0xFF2F8C6B);

  /// 主题种子色
  static const Color seedColor = Color(0xFF2F8C6B);

  /// 分类占比环形图配色（循环取用）
  static const List<Color> chartPalette = [
    Color(0xFF2F8C6B),
    Color(0xFF4E9FD8),
    Color(0xFFE5A13E),
    Color(0xFF9B72D8),
    Color(0xFFD86A5B),
    Color(0xFF5BB9A6),
    Color(0xFFC2B036),
    Color(0xFF8C9AA8),
  ];
}
