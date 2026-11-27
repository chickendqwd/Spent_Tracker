import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spent_tracker/core/theme/app_schemes.dart';
import 'package:spent_tracker/core/theme/app_theme.dart';

/// 对比度（WCAG 相对亮度比）
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('10 套配色方案的可读性下限', () {
    for (final scheme in AppPaletteSchemes.all) {
      final light = buildLightPalette(scheme);
      final dark = buildDarkPalette(scheme);

      test('${scheme.id} 亮色：正文/次要文字/语义色/主卡白字', () {
        expect(_contrast(light.ink, light.card), greaterThan(7));
        expect(_contrast(light.ink, light.bgBottom), greaterThan(7));
        expect(_contrast(light.muted, light.card), greaterThan(4));
        // 深色主卡上的白字
        expect(_contrast(Colors.white, light.primaryDeep), greaterThan(7));
        // 支出 / 收入语义色至少达到大字号 AA（3:1）
        expect(_contrast(light.expense, light.card), greaterThan(3));
        expect(_contrast(light.income, light.card), greaterThan(3));
      });

      test('${scheme.id} 暗色：正文/次要文字/语义色', () {
        expect(_contrast(dark.ink, dark.card), greaterThan(7));
        expect(_contrast(dark.muted, dark.card), greaterThan(4));
        expect(_contrast(dark.expense, dark.card), greaterThan(3));
        expect(_contrast(dark.income, dark.card), greaterThan(3));
      });
    }

    test('强调色上的文字始终可读（chip / FAB）', () {
      for (final scheme in AppPaletteSchemes.all) {
        for (final palette in [
          buildLightPalette(scheme),
          buildDarkPalette(scheme),
        ]) {
          final on = AppTheme.bestOnColor(palette.primary);
          expect(_contrast(on, palette.primary), greaterThan(3));
        }
      }
    });

    test('默认方案与 AppPalette 常量保持一致', () {
      final light = buildLightPalette(AppPaletteSchemes.gray);
      final dark = buildDarkPalette(AppPaletteSchemes.gray);
      expect(light.primary, AppPalette.light.primary);
      expect(dark.primary, AppPalette.dark.primary);
      expect(dark.income, AppPalette.dark.income);
    });
  });
}
