import 'package:flutter/material.dart';

import '../constants.dart';

/// 语义化配色：亮/暗主题各一套，页面统一从 `context.palette` 取色，
/// 不再硬编码具体颜色，从而支持深色模式。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.expense,
    required this.income,
    required this.muted,
    required this.chartPalette,
    required this.onChartLabel,
    required this.accent,
  });

  /// 支出金额颜色
  final Color expense;

  /// 收入金额颜色
  final Color income;

  /// 次要文字（说明、轴标签、标签列）
  final Color muted;

  /// 分类占比等图表循环配色
  final List<Color> chartPalette;

  /// 图表切片/提示文字颜色
  final Color onChartLabel;

  /// 强调色（星标、警示徽标）
  final Color accent;

  static const AppPalette light = AppPalette(
    expense: Color(0xFFE5484D),
    income: Color(0xFF2F8C6B),
    muted: Color(0xFF6B7280),
    onChartLabel: Colors.white,
    accent: Color(0xFFE5A13E),
    chartPalette: [
      Color(0xFF2F8C6B),
      Color(0xFF4E9FD8),
      Color(0xFFE5A13E),
      Color(0xFF9B72D8),
      Color(0xFFD86A5B),
      Color(0xFF5BB9A6),
      Color(0xFFC2B036),
      Color(0xFF8C9AA8),
    ],
  );

  static const AppPalette dark = AppPalette(
    expense: Color(0xFFFF7B7E),
    income: Color(0xFF5BC79C),
    muted: Color(0xFF9AA3AE),
    onChartLabel: Colors.white,
    accent: Color(0xFFF0B44D),
    chartPalette: [
      Color(0xFF4FBF95),
      Color(0xFF6FB4E8),
      Color(0xFFF0B44D),
      Color(0xFFB191E8),
      Color(0xFFE8897C),
      Color(0xFF7ACFC0),
      Color(0xFFD6C750),
      Color(0xFFA3AFBA),
    ],
  );

  @override
  AppPalette copyWith({
    Color? expense,
    Color? income,
    Color? muted,
    List<Color>? chartPalette,
    Color? onChartLabel,
    Color? accent,
  }) {
    return AppPalette(
      expense: expense ?? this.expense,
      income: income ?? this.income,
      muted: muted ?? this.muted,
      chartPalette: chartPalette ?? this.chartPalette,
      onChartLabel: onChartLabel ?? this.onChartLabel,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      income: Color.lerp(income, other.income, t) ?? income,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      chartPalette: chartPalette,
      onChartLabel: Color.lerp(onChartLabel, other.onChartLabel, t) ?? onChartLabel,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
    );
  }
}

/// 便捷访问器：`context.palette.expense`。
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// 应用主题构建：亮色 / 暗色共用同一 seed，仅亮度与语义色不同。
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConstants.seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      extensions: [palette],
    );
  }
}
