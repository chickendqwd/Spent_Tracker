import 'package:flutter/material.dart';

/// 语义化配色（UI 重构版）：
/// 亮/暗两套共用同一套语义键，页面统一从 `context.palette` 取色。
///
/// 设计口径见《Spent_Tracker_UI设计说明.md》：
/// 低饱和灰青绿主色、陶土辅助色、白→浅灰渐变背景、斜切角卡片。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.expense,
    required this.income,
    required this.muted,
    required this.chartPalette,
    required this.onChartLabel,
    required this.accent,
    required this.primary,
    required this.primaryDeep,
    required this.card,
    required this.cardTint,
    required this.bgTop,
    required this.bgBottom,
    required this.ink,
    required this.divider,
  });

  /// 支出金额颜色（陶土红棕，不用纯红）
  final Color expense;

  /// 收入金额颜色（橄榄绿）
  final Color income;

  /// 次要文字（说明、轴标签、标签列）
  final Color muted;

  /// 分类占比等图表循环配色
  final List<Color> chartPalette;

  /// 图表切片/提示文字颜色
  final Color onChartLabel;

  /// 强调色（警示徽标、次要点缀）
  final Color accent;

  /// 主色（灰青绿）
  final Color primary;

  /// 主色加深版本（强调、图标底色）
  final Color primaryDeep;

  /// 卡片底色
  final Color card;

  /// 卡片浅色版本（主卡、浅底块）
  final Color cardTint;

  /// 页面背景渐变起点
  final Color bgTop;

  /// 页面背景渐变终点
  final Color bgBottom;

  /// 主文字色
  final Color ink;

  /// 分隔线 / 细描边
  final Color divider;

  static const AppPalette light = AppPalette(
    expense: Color(0xFFB0563F),
    income: Color(0xFF6B8E5A),
    muted: Color(0xFF7A8288),
    onChartLabel: Colors.white,
    accent: Color(0xFFB98A6F),
    primary: Color(0xFF5E8B7E),
    primaryDeep: Color(0xFF1F5F56),
    card: Color(0xFFFBFAF7),
    cardTint: Color(0xFFF0F5F2),
    bgTop: Color(0xFFFFFFFF),
    bgBottom: Color(0xFFEEF0F2),
    ink: Color(0xFF202020),
    divider: Color(0xFFDFE4E6),
    chartPalette: [
      Color(0xFF5E8B7E),
      Color(0xFF7FA6B8),
      Color(0xFFC9B87A),
      Color(0xFFB98A6F),
      Color(0xFF6B8E5A),
      Color(0xFF9AA3A8),
    ],
  );

  static const AppPalette dark = AppPalette(
    expense: Color(0xFFE08970),
    income: Color(0xFF8FB87B),
    muted: Color(0xFF98A3A8),
    onChartLabel: Colors.white,
    accent: Color(0xFFC89B7F),
    primary: Color(0xFF8CBBAD),
    primaryDeep: Color(0xFF2E7265),
    card: Color(0xFF1D2427),
    cardTint: Color(0xFF24312D),
    bgTop: Color(0xFF14191B),
    bgBottom: Color(0xFF0E1214),
    ink: Color(0xFFEDF1F0),
    divider: Color(0xFF2C3437),
    chartPalette: [
      Color(0xFF8CBBAD),
      Color(0xFF8FB8CC),
      Color(0xFFD9C58C),
      Color(0xFFC89B7F),
      Color(0xFF8FB87B),
      Color(0xFFA9B2B7),
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
    Color? primary,
    Color? primaryDeep,
    Color? card,
    Color? cardTint,
    Color? bgTop,
    Color? bgBottom,
    Color? ink,
    Color? divider,
  }) {
    return AppPalette(
      expense: expense ?? this.expense,
      income: income ?? this.income,
      muted: muted ?? this.muted,
      chartPalette: chartPalette ?? this.chartPalette,
      onChartLabel: onChartLabel ?? this.onChartLabel,
      accent: accent ?? this.accent,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      card: card ?? this.card,
      cardTint: cardTint ?? this.cardTint,
      bgTop: bgTop ?? this.bgTop,
      bgBottom: bgBottom ?? this.bgBottom,
      ink: ink ?? this.ink,
      divider: divider ?? this.divider,
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
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t) ?? primaryDeep,
      card: Color.lerp(card, other.card, t) ?? card,
      cardTint: Color.lerp(cardTint, other.cardTint, t) ?? cardTint,
      bgTop: Color.lerp(bgTop, other.bgTop, t) ?? bgTop,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t) ?? bgBottom,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
    );
  }
}

/// 便捷访问器：`context.palette.expense`。
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// 应用主题构建：亮色 / 暗色共用同一套语义键与布局，只换明暗与配色。
class AppTheme {
  AppTheme._();

  /// 卡片圆角
  static const double cardRadius = 14;

  /// 卡片右上角斜切宽度
  static const double cardSlant = 26;

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final isLight = brightness == Brightness.light;
    final onPrimary = isLight ? Colors.white : const Color(0xFF0F1B18);

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      onPrimary: onPrimary,
      primaryContainer: palette.cardTint,
      onPrimaryContainer: palette.primaryDeep,
      secondary: palette.accent,
      onSecondary: Colors.white,
      surface: palette.card,
      onSurface: palette.ink,
      surfaceContainerLowest: palette.bgTop,
      surfaceContainerLow: palette.card,
      surfaceContainer: palette.cardTint,
      surfaceContainerHigh: palette.cardTint,
      surfaceContainerHighest: palette.divider,
      error: palette.expense,
      onError: Colors.white,
      outline: palette.divider,
      outlineVariant: palette.divider,
      inverseSurface: palette.ink,
      onInverseSurface: palette.card,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    ).textTheme;

    final textTheme = base
        .apply(
          bodyColor: palette.ink,
          displayColor: palette.ink,
        )
        .copyWith(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: palette.ink,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: palette.ink,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: palette.muted,
          ),
          bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: palette.ink),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: palette.ink),
          bodySmall: TextStyle(fontSize: 12, height: 1.35, color: palette.muted),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: palette.ink,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: palette.muted,
          ),
        );

    final roundedCard = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: palette.bgTop,
      splashFactory: InkSparkle.splashFactory,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 60,
        iconTheme: IconThemeData(color: palette.ink, size: 22),
        actionsIconTheme: IconThemeData(color: palette.ink, size: 22),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: palette.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: roundedCard,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: palette.primary.withValues(alpha: isLight ? 0.16 : 0.24),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? palette.primaryDeep : palette.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? palette.primaryDeep : palette.muted,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: onPrimary,
        elevation: 3,
        highlightElevation: 1,
        shape: const CircleBorder(),
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primaryDeep,
          minimumSize: const Size(0, 40),
          side: BorderSide(color: palette.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primaryDeep,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.cardTint,
        selectedColor: palette.primary,
        disabledColor: palette.cardTint,
        surfaceTintColor: Colors.transparent,
        side: BorderSide(color: palette.divider),
        shape: StadiumBorder(side: BorderSide(color: palette.divider)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: onPrimary,
        ),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return palette.primary;
            return palette.cardTint;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return onPrimary;
            return palette.ink;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(color: palette.divider);
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(fontSize: 14, color: palette.muted),
        labelStyle: TextStyle(fontSize: 13, color: palette.muted),
        floatingLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.primaryDeep,
        ),
        prefixStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.expense, width: 1.6),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.divider,
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.primaryDeep,
        textColor: palette.ink,
        subtitleTextStyle: TextStyle(fontSize: 12, color: palette.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        dragHandleColor: palette.muted,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: palette.ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: TextStyle(color: palette.card, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: TextStyle(fontSize: 14, color: palette.ink),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: palette.cardTint,
        headerForegroundColor: palette.ink,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return palette.ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return Colors.transparent;
        }),
        todayBorder: BorderSide(color: palette.primary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return palette.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return palette.divider;
        }),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          palette.muted.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
