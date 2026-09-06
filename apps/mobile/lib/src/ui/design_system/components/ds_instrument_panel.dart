import 'package:flutter/material.dart';

import '../tokens/ds_opacity.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadow.dart';
import '../tokens/ds_spacing.dart';
import '../tokens/ds_theme_extension.dart';

class DSInstrumentPanel extends StatelessWidget {
  const DSInstrumentPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.headerIcon,
    this.showGrid = true,
    this.glow = DSShadow.glowCeladon,
    this.padding = const EdgeInsets.all(DSSpacing.lg),
    this.headerPadding = const EdgeInsets.fromLTRB(
      DSSpacing.lg,
      DSSpacing.md,
      DSSpacing.lg,
      DSSpacing.sm,
    ),
  });

  final Widget child;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? headerIcon;
  final bool showGrid;
  final List<BoxShadow> glow;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry headerPadding;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ds.glass,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: ds.metalLine, width: 1),
        boxShadow: glow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DSRadius.lg),
        child: Stack(
          children: [
            if (showGrid)
              Positioned.fill(
                child: CustomPaint(painter: _InstrumentGridPainter(ds: ds)),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: headerPadding,
                  child: Row(
                    children: [
                      if (headerIcon != null) ...[
                        Icon(headerIcon, size: 15, color: ds.celadonDeep),
                        const SizedBox(width: DSSpacing.xs),
                      ],
                      _StatusDot(ds: ds),
                      const SizedBox(width: DSSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: ds.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: ds.textMuted,
                                  fontSize: 9,
                                  height: 1.3,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: .8,
                  color: ds.metalLine.withValues(alpha: .8),
                  indent: DSSpacing.lg,
                  endIndent: DSSpacing.lg,
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.ds});

  final DSColorsScheme ds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: ds.celadonDeep, shape: BoxShape.circle),
    );
  }
}

class _InstrumentGridPainter extends CustomPainter {
  const _InstrumentGridPainter({required this.ds});

  final DSColorsScheme ds;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = ds.moonWhite.withValues(alpha: DSOpacity.faint)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .5;
    const unit = 24.0;
    final path = Path();
    for (var x = unit; x < size.width; x += unit) {
      path.moveTo(x, 0);
      path.lineTo(x, size.height);
    }
    for (var y = unit; y < size.height; y += unit) {
      path.moveTo(0, y);
      path.lineTo(size.width, y);
    }
    canvas.drawPath(path, gridPaint);

    final crossPaint = Paint()
      ..color = ds.celadon.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final cross = Path()
      ..moveTo(size.width / 2 - 10, size.height / 2)
      ..lineTo(size.width / 2 + 10, size.height / 2)
      ..moveTo(size.width / 2, size.height / 2 - 10)
      ..lineTo(size.width / 2, size.height / 2 + 10);
    canvas.drawPath(cross, crossPaint);
  }

  @override
  bool shouldRepaint(covariant _InstrumentGridPainter oldDelegate) =>
      oldDelegate.ds != ds;
}
