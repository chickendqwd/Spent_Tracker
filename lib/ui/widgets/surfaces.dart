import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 页面背景：白 → 浅灰（暗色模式为深灰）纵向渐变，无纹样。
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgTop, palette.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

/// 斜切角卡片的裁剪路径：四角圆角，右上角做一道斜切（呼应票据语言）。
class SlantCardClipper extends CustomClipper<Path> {
  const SlantCardClipper({
    this.radius = AppTheme.cardRadius,
    this.slant = AppTheme.cardSlant,
  });

  final double radius;
  final double slant;

  @override
  Path getClip(Size size) {
    final r = math.min(radius, size.height / 2);
    final s = math.min(slant, size.width * 0.4);
    return Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - s, 0)
      ..lineTo(size.width, s)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - r,
        size.height,
      )
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant SlantCardClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.slant != slant;
}

/// 统一卡片：斜切角 + 左侧主色竖条，可选浅色调底与点击。
///
/// 用 [PhysicalShape] 承载裁剪与柔和投影；左侧色条按内容高度自适应。
class SlantCard extends StatelessWidget {
  const SlantCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 16, 14),
    this.tint = false,
    this.accentColor,
    this.background,
    this.barWidth = 4,
    this.elevation = 1.4,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// true 时用浅色 tint 底（主卡/强调块）
  final bool tint;

  /// 指定卡面底色（如深色 hero 主卡），优先于 [tint]
  final Color? background;

  /// 左侧色条颜色，默认取主色
  final Color? accentColor;

  final double barWidth;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final barColor = accentColor ?? palette.primary;
    final color = background ?? (tint ? palette.cardTint : palette.card);

    final card = PhysicalShape(
      clipper: const SlantCardClipper(),
      color: color,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            width: barWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(2),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap == null) return card;
    // 卡面不透明，点击反馈交给 InkWell 的水波纹外扩即可，
    // 不再用 customBorder 裁剪（PhysicalShape 已负责外形与投影）。
    return InkWell(onTap: onTap, child: card);
  }
}

/// 分类 Emoji 头像：浅灰圆形底 + 原生 Emoji。
class EmojiBadge extends StatelessWidget {
  const EmojiBadge({
    super.key,
    required this.emoji,
    this.size = 40,
    this.background,
  });

  final String emoji;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? palette.cardTint,
        shape: BoxShape.circle,
      ),
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.46, height: 1),
      ),
    );
  }
}

/// 页面/模块标题：粗体大字号，标题后附一枚主色小方标记（斜切感）。
/// 文字保持单一 Text，不拆字，保证读屏与文本检索完整可读。
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.text, {
    super.key,
    this.fontSize = 22,
    this.color,
    this.mark = true,
  });

  final String text;
  final double fontSize;
  final Color? color;

  /// 是否显示高亮标记
  final bool mark;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ink = color ?? palette.ink;
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: ink,
      height: 1.15,
    );
    if (!mark || text.isEmpty) {
      return Text(text, style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        _Square(size: fontSize * 0.36, color: palette.primary),
      ],
    );
  }
}

/// 小方标记（斜切感），用于标题后置标记与点缀。
class _Square extends StatelessWidget {
  const _Square({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(width: size, height: size, color: color),
    );
  }
}

/// 模块标题行：左侧标题 + 右侧可选操作。
class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.title,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle case final String s)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    s,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// 胶囊筛选按钮：选中态主色填充白字，未选中浅底细边。
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final onPrimary =
        Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF0F1B18);
    final fg = selected ? onPrimary : palette.ink;

    return Material(
      color: selected ? palette.primary : palette.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? palette.primary : palette.divider,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
