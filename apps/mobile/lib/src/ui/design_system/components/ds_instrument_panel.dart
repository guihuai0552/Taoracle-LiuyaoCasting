import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_opacity.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadow.dart';
import '../tokens/ds_spacing.dart';

/// 仪器面板：顶部状态栏式标题 + 细网格/刻度装饰 + 内容区。
///
/// 用于承载关键术数信息：本卦/变卦、六爻、六亲/六神、世应、用神提示。
/// 只做展示容器，不承载业务判断。
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DSColors.glass,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: DSColors.metalLine, width: 1),
        boxShadow: glow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DSRadius.lg),
        child: Stack(
          children: [
            if (showGrid)
              Positioned.fill(
                child: CustomPaint(painter: const _InstrumentGridPainter()),
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
                        Icon(headerIcon, size: 15, color: DSColors.celadonDeep),
                        const SizedBox(width: DSSpacing.xs),
                      ],
                      const _StatusDot(),
                      const SizedBox(width: DSSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: DSColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  color: DSColors.textMuted,
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
                  color: DSColors.metalLine.withValues(alpha: .8),
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

/// 顶部状态灯：青铜小圆点，模拟仪器通电指示。
class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: DSColors.celadonDeep,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 仪器网格：极淡网格 + 中心十字刻度，装饰面板内部。
class _InstrumentGridPainter extends CustomPainter {
  const _InstrumentGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = DSColors.moonWhite.withValues(alpha: DSOpacity.faint)
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
      ..color = DSColors.celadon.withValues(alpha: .16)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
