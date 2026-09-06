import 'package:flutter/material.dart';

import 'design_system/app_theme_v1.dart';
import 'design_system/tokens/ds_colors.dart';
import 'design_system/tokens/ds_colors_v1.dart';
import 'design_system/tokens/ds_theme_extension.dart';

abstract final class LiuyaoColors {
  static const paper = DSColors.background;
  static const paperRaised = DSColors.surfaceRaised;
  static const parchment = DSColors.surface;
  static const ink = DSColors.textPrimary;
  static const inkMedium = DSColors.textSecondary;
  static const inkMuted = DSColors.textMuted;
  static const inkFaint = DSColors.hairlineStrong;
  static const cinnabar = DSColors.cinnabar;
  static const jade = DSColors.jade;
  static const wood = DSColors.wood;
  static const fire = DSColors.fire;
  static const earth = DSColors.earth;
  static const metal = DSColors.metal;
  static const water = DSColors.water;
}

abstract final class LiuyaoColorsV1 {
  static const paper = DSColorsV1.background;
  static const paperRaised = DSColorsV1.surfaceLight;
  static const parchment = DSColorsV1.surfaceLightSunken;
  static const ink = DSColorsV1.textPrimary;
  static const inkMedium = DSColorsV1.textSecondary;
  static const inkMuted = DSColorsV1.textMuted;
  static const inkFaint = DSColorsV1.hairlineStrong;
  static const cinnabar = DSColorsV1.warning;
  static const jade = DSColorsV1.accent;
  static const wood = DSColorsV1.wood;
  static const fire = DSColorsV1.fire;
  static const earth = DSColorsV1.earth;
  static const metal = DSColorsV1.metal;
  static const water = DSColorsV1.water;
}

abstract final class LiuyaoSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class LiuyaoRadii {
  static const small = 8.0;
  static const card = 16.0;
  static const large = 18.0;
  static const phone = 24.0;
}

class LiuyaoColorsContext {
  const LiuyaoColorsContext(this.ds);

  final DSColorsScheme ds;

  Color get paper => ds.background;
  Color get paperRaised => ds.surfaceRaised;
  Color get parchment => ds.surface;
  Color get ink => ds.textPrimary;
  Color get inkMedium => ds.textSecondary;
  Color get inkMuted => ds.textMuted;
  Color get inkFaint => ds.hairlineStrong;
  Color get cinnabar => ds.cinnabar;
  Color get jade => ds.jade;
  Color get wood => ds.wood;
  Color get fire => ds.fire;
  Color get earth => ds.earth;
  Color get metal => ds.metal;
  Color get water => ds.water;
}

extension LiuyaoColorsContextExt on BuildContext {
  LiuyaoColorsContext get lc => LiuyaoColorsContext(ds);
}

ThemeData buildLiuyaoTheme() => buildDaoyuTheme();

ThemeData buildLiuyaoDarkTheme() => buildDaoyuDarkTheme();

class LiuyaoPaperBackground extends StatelessWidget {
  const LiuyaoPaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DSDaoyuBackground(child: child);
}

class ChineseLatticePainter extends CustomPainter {
  const ChineseLatticePainter({this.opacity = .09, this.lineColor});

  final double opacity;
  final Color? lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (lineColor ?? LiuyaoColors.inkMedium).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75;
    const unit = 24.0;

    void corner(Offset origin, double sx, double sy) {
      final path = Path();
      for (var index = 0; index < 4; index++) {
        final inset = index * 6.0;
        final width = unit * (4 - index * .55);
        final height = unit * (4 - index * .55);
        path.addRect(
          Rect.fromPoints(
            Offset(origin.dx + sx * inset, origin.dy + sy * inset),
            Offset(
              origin.dx + sx * (inset + width),
              origin.dy + sy * (inset + height),
            ),
          ),
        );
      }
      path.moveTo(origin.dx, origin.dy + sy * unit * 2);
      path.relativeLineTo(sx * unit * 4, 0);
      path.moveTo(origin.dx + sx * unit * 2, origin.dy);
      path.relativeLineTo(0, sy * unit * 4);
      canvas.drawPath(path, paint);
    }

    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);

    final grain = Paint()
      ..color = (lineColor ?? LiuyaoColors.inkMedium).withValues(
        alpha: opacity * .32,
      )
      ..strokeWidth = .7;
    for (var y = 18.0; y < size.height; y += 47) {
      final x = (y * 1.73) % size.width;
      canvas.drawCircle(Offset(x, y), .55, grain);
    }
  }

  @override
  bool shouldRepaint(covariant ChineseLatticePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.lineColor != lineColor;
}

class LiuyaoPaperCard extends StatelessWidget {
  const LiuyaoPaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = LiuyaoRadii.card,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ds.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: ds.hairlineStrong, width: .8) : null,
      ),
      child: child,
    );
  }
}

class LiuyaoSealMark extends StatelessWidget {
  const LiuyaoSealMark({
    super.key,
    required this.character,
    required this.label,
  });

  final String character;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return CustomPaint(
      painter: _SealLatticePainter(cinnabar: ds.cinnabar),
      child: SizedBox(
        width: 64,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              character,
              style: TextStyle(
                color: ds.cinnabar,
                fontFamily: 'DaoyuSong',
                fontFamilyFallback: const ['Songti SC', 'Noto Serif CJK SC'],
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: ds.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SealLatticePainter extends CustomPainter {
  const _SealLatticePainter({required this.cinnabar});

  final Color cinnabar;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cinnabar
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(outer, paint);
    canvas.drawRect(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      paint..color = cinnabar.withValues(alpha: .66),
    );
    final lattice = Path()
      ..moveTo(7, size.height / 2)
      ..lineTo(15, size.height / 2)
      ..moveTo(size.width - 15, size.height / 2)
      ..lineTo(size.width - 7, size.height / 2)
      ..moveTo(size.width / 2, 7)
      ..lineTo(size.width / 2, 15)
      ..moveTo(size.width / 2, size.height - 15)
      ..lineTo(size.width / 2, size.height - 7);
    canvas.drawPath(lattice, paint);
  }

  @override
  bool shouldRepaint(covariant _SealLatticePainter oldDelegate) =>
      oldDelegate.cinnabar != cinnabar;
}
