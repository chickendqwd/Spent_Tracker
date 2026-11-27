import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 一套三色配色方案：主卡（最深）、强调（最饱和）、页面底（最浅）。
///
/// 角色映射固定：主卡色 → 结余主卡底 / 标题强调；强调色 → 选中胶囊、
/// 预算条、趋势主折线、标题小方块；底色 → 页面背景与卡片浅底。
@immutable
class AppPaletteScheme {
  const AppPaletteScheme({
    required this.id,
    required this.hero,
    required this.accent,
    required this.surface,
    this.monochrome = false,
  });

  /// 持久化用的稳定标识（不要改）
  final String id;

  /// 最深色（结余主卡底）
  final Color hero;

  /// 最饱和色（强调色）
  final Color accent;

  /// 最浅色（页面底）
  final Color surface;

  /// 黑白灰方案直接复用 AppPalette.light / dark 常量
  final bool monochrome;

  /// 主卡实际底色：过亮的 hero 压暗到可以承载白字
  Color get heroCard {
    if (monochrome) return const Color(0xFF121212);
    final hsl = HSLColor.fromColor(hero);
    if (hsl.lightness <= 0.30) return hero;
    return hsl.withLightness(0.26).toColor();
  }

  /// 设置页展示用的 3 个小球（主卡 / 强调 / 底色）
  List<Color> get dots => [heroCard, accent, surface];
}

/// 10 套可选配色（第 1 套为默认黑白灰）。
class AppPaletteSchemes {
  AppPaletteSchemes._();

  static const AppPaletteScheme gray = AppPaletteScheme(
    id: 'gray',
    hero: Color(0xFF121212),
    accent: Color(0xFF8A8A8A),
    surface: Color(0xFFF2F2F2),
    monochrome: true,
  );

  static const AppPaletteScheme deepForest = AppPaletteScheme(
    id: 'deepForest',
    hero: Color(0xFF123524),
    accent: Color(0xFF8FA98F),
    surface: Color(0xFFF3F1EA),
  );

  static const AppPaletteScheme glacier = AppPaletteScheme(
    id: 'glacier',
    hero: Color(0xFF1A3D50),
    accent: Color(0xFF6D9DB5),
    surface: Color(0xFFE8F1F5),
  );

  static const AppPaletteScheme navyGold = AppPaletteScheme(
    id: 'navyGold',
    hero: Color(0xFF0A2463),
    accent: Color(0xFFE8C547),
    surface: Color(0xFFF3F4F7),
  );

  static const AppPaletteScheme peachSea = AppPaletteScheme(
    id: 'peachSea',
    hero: Color(0xFF344C63),
    accent: Color(0xFFE4B3A9),
    surface: Color(0xFFDDEAF2),
  );

  static const AppPaletteScheme electricBerry = AppPaletteScheme(
    id: 'electricBerry',
    hero: Color(0xFF124BA5),
    accent: Color(0xFFE6466A),
    surface: Color(0xFFF8DCEB),
  );

  static const AppPaletteScheme terracotta = AppPaletteScheme(
    id: 'terracotta',
    hero: Color(0xFF3B2A20),
    accent: Color(0xFFC1603F),
    surface: Color(0xFFF5F0E8),
  );

  static const AppPaletteScheme forestNoir = AppPaletteScheme(
    id: 'forestNoir',
    hero: Color(0xFF1A1A1A),
    accent: Color(0xFF2D4A3E),
    surface: Color(0xFFF5E6C8),
  );

  static const AppPaletteScheme skyWood = AppPaletteScheme(
    id: 'skyWood',
    hero: Color(0xFF6E93AC),
    accent: Color(0xFFC8AD88),
    surface: Color(0xFFF7F7F4),
  );

  static const AppPaletteScheme roseStone = AppPaletteScheme(
    id: 'roseStone',
    hero: Color(0xFF5E5A57),
    accent: Color(0xFFD9A8AD),
    surface: Color(0xFFF6EEE7),
  );

  /// 设置页展示顺序（第一个是默认）
  static const List<AppPaletteScheme> all = [
    gray,
    deepForest,
    glacier,
    navyGold,
    peachSea,
    electricBerry,
    terracotta,
    forestNoir,
    skyWood,
    roseStone,
  ];

  static AppPaletteScheme byId(Object? id) => all.firstWhere(
        (s) => s.id == id,
        orElse: () => gray,
      );
}

// ---------------------------------------------------------------------------
// 三色派生色板
// ---------------------------------------------------------------------------

/// 语义色锚点：支出偏红、收入偏绿；派生时混入 hero 让整体同色系。
const Color _expenseAnchor = Color(0xFFB0563F);
const Color _incomeAnchor = Color(0xFF6B8E5A);

Color _tone(Color c, {double? lightness, double? saturation}) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((lightness ?? hsl.lightness).clamp(0.0, 1.0))
      .withSaturation((saturation ?? hsl.saturation).clamp(0.0, 1.0))
      .toColor();
}

List<Color> _chart(Color hero, Color accent, Color surface) => [
      accent,
      hero,
      Color.lerp(hero, surface, 0.38)!,
      Color.lerp(accent, surface, 0.45)!,
      _tone(hero, lightness: 0.58, saturation: 0.10),
      Color.lerp(hero, const Color(0xFF8A8A8A), 0.5)!,
    ];

/// 亮色色板：底色做渐变底与卡面，强调色做主色，hero 做深色强调与白字卡。
AppPalette buildLightPalette(AppPaletteScheme scheme) {
  if (scheme.monochrome) return AppPalette.light;
  final hero = scheme.heroCard;
  final accent = scheme.accent;
  final surface = scheme.surface;

  return AppPalette(
    expense: Color.lerp(_expenseAnchor, hero, 0.16)!,
    income: Color.lerp(_incomeAnchor, hero, 0.22)!,
    muted: _tone(hero, lightness: 0.42, saturation: 0.12),
    onChartLabel: Colors.white,
    accent: Color.lerp(accent, hero, 0.18)!,
    primary: accent,
    primaryDeep: hero,
    card: Color.lerp(surface, Colors.white, 0.85)!,
    cardTint: Color.lerp(surface, Colors.white, 0.66)!,
    bgTop: Color.lerp(surface, Colors.white, 0.30)!,
    bgBottom: surface,
    ink: _tone(hero, lightness: 0.14, saturation: 0.28),
    divider: Color.lerp(surface, hero, 0.10)!,
    chartPalette: _chart(hero, accent, Color.lerp(surface, Colors.white, 0.85)!),
  );
}

/// 暗色色板：hero 做底，强调色提亮做主色，底色做暖白文字。
AppPalette buildDarkPalette(AppPaletteScheme scheme) {
  if (scheme.monochrome) return AppPalette.dark;
  final hero = scheme.heroCard;
  final accent = scheme.accent;

  return AppPalette(
    expense: _tone(
      Color.lerp(_expenseAnchor, Colors.white, 0.55)!,
      lightness: 0.68,
      saturation: 0.34,
    ),
    income: _tone(
      Color.lerp(_incomeAnchor, Colors.white, 0.45)!,
      lightness: 0.70,
      saturation: 0.30,
    ),
    muted: _tone(hero, lightness: 0.62, saturation: 0.10),
    onChartLabel: Colors.white,
    accent: _tone(accent, lightness: 0.62),
    primary: _tone(accent, lightness: 0.68),
    primaryDeep: _tone(accent, lightness: 0.80),
    card: _tone(hero, lightness: 0.15, saturation: 0.20),
    cardTint: _tone(hero, lightness: 0.21, saturation: 0.16),
    bgTop: _tone(hero, lightness: 0.10, saturation: 0.18),
    bgBottom: _tone(hero, lightness: 0.055, saturation: 0.14),
    ink: Color.lerp(scheme.surface, Colors.white, 0.86)!,
    divider: _tone(hero, lightness: 0.28, saturation: 0.14),
    chartPalette: _chart(
      _tone(hero, lightness: 0.30, saturation: 0.20),
      _tone(accent, lightness: 0.70),
      _tone(hero, lightness: 0.15, saturation: 0.20),
    ),
  );
}
