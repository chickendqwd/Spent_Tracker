import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_schemes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../state/theme_providers.dart';
import '../widgets/surfaces.dart';

/// 配色方案设置：10 套三色配色，每项名字左侧是 3 个色球（主卡 / 强调 / 底色）。
/// 默认黑白灰；选中即时生效并持久化。
class PalettePage extends ConsumerWidget {
  const PalettePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final current = ref.watch(paletteSchemeProvider);
    final notifier = ref.read(paletteSchemeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: SectionTitle(l10n.paletteTitle)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                l10n.paletteNote,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: palette.muted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SlantCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final (i, scheme) in AppPaletteSchemes.all.indexed) ...[
                    _SchemeRow(
                      scheme: scheme,
                      selected: scheme.id == current.id,
                      onTap: () => notifier.set(scheme),
                    ),
                    if (i != AppPaletteSchemes.all.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 70, right: 16),
                        child: Container(height: 1, color: palette.divider),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchemeRow extends StatelessWidget {
  const _SchemeRow({
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final AppPaletteScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
        child: Row(
          children: [
            _ThreeDots(colors: scheme.dots),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.paletteSchemeName(scheme),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  if (scheme.monochrome) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: palette.cardTint,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: palette.divider),
                      ),
                      child: Text(
                        l10n.paletteDefault,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? palette.primary : palette.divider,
            ),
          ],
        ),
      ),
    );
  }
}

/// 三色小球：主卡 / 强调 / 底色，互相轻微重叠。
class _ThreeDots extends StatelessWidget {
  const _ThreeDots({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const size = 14.0;
    const step = 11.0;
    return SizedBox(
      width: size + step * (colors.length - 1),
      height: size,
      child: Stack(
        children: [
          for (final (i, c) in colors.indexed)
            Positioned(
              left: i * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.card,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
