import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_motion.dart';

/// 六爻爻线 · 纯展示组件。
///
/// 只接收展示参数（阴阳、是否动爻、动爻老阴老阳、世应高亮），不承载任何
/// 业务判断，也不参与起卦/变卦逻辑。用作卦面爻线的「包裹增强」样式：
/// 暗色下的月白爻线、克制朱砂动爻辉光、玉青世应高亮、自下而上入场。
class DSHexagramLine extends StatefulWidget {
  const DSHexagramLine({
    super.key,
    required this.yang,
    this.changing = false,
    this.changingValue,
    this.highlight = false,
    this.pulse = false,
    this.animate = false,
    this.animationDelay = Duration.zero,
  });

  /// 阳爻为 true；阴爻为 false。
  final bool yang;

  /// 是否为动爻。
  final bool changing;

  /// 动爻数值：9（老阳 → Ｏ）或 6（老阴 → Χ）。非动爻时忽略。
  final int? changingValue;

  /// 世应等关键爻位的玉青高亮。
  final bool highlight;

  /// 循环辉光脉冲（动爻能量流动）；仅在 [changing] 时建议开启。
  final bool pulse;

  /// 入场动效。
  final bool animate;

  /// 入场延迟（用于六爻自下而上依次出现）。
  final Duration animationDelay;

  @override
  State<DSHexagramLine> createState() => _DSHexagramLineState();
}

class _DSHexagramLineState extends State<DSHexagramLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool get _pulsing => widget.pulse;

  @override
  void initState() {
    super.initState();
    if (_pulsing) {
      _pulse = AnimationController(vsync: this, duration: DSMotion.slow)
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (_pulsing) _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = widget.highlight
        ? DSColors.jade
        : widget.changing
        ? DSColors.cinnabarSoft
        : DSColors.textPrimary;
    final glowColor = widget.changing
        ? DSColors.glowCinnabar
        : widget.highlight
        ? DSColors.glowJade
        : Colors.transparent;

    final line = SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: _pulsing ? _pulse : kAlwaysCompleteAnimation,
        builder: (context, _) {
          final glowOpacity = _pulsing ? _pulse.value : 1.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _YaoLinePainter(
                    yang: widget.yang,
                    color: lineColor,
                    glowColor: glowColor,
                    glowOpacity: glowOpacity,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              SizedBox(
                width: 15,
                height: 14,
                child: widget.changing
                    ? Text(
                        widget.changingValue == 9 ? 'Ｏ' : 'Χ',
                        style: const TextStyle(
                          color: DSColors.cinnabarSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      )
                    : null,
              ),
            ],
          );
        },
      ),
    );

    if (!widget.animate) return line;
    final total = DSMotion.ritual;
    final start = (widget.animationDelay.inMilliseconds / total.inMilliseconds)
        .clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: .9 + .1 * value,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
      child: line,
    );
  }
}

/// 爻线绘制：阳爻一条实线，阴爻两条断线；动爻加柔和辉光带。
class _YaoLinePainter extends CustomPainter {
  const _YaoLinePainter({
    required this.yang,
    required this.color,
    required this.glowColor,
    required this.glowOpacity,
  });

  final bool yang;
  final Color color;
  final Color glowColor;
  final double glowOpacity;

  static const double _lineHeight = 4;
  static const double _yinGap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cy = size.height / 2;

    if (glowColor != Colors.transparent && glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: glowOpacity * .7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRect(Rect.fromLTWH(0, cy - 11, size.width, 9), glowPaint);
      canvas.drawRect(Rect.fromLTWH(0, cy + 2, size.width, 9), glowPaint);
    }

    if (yang) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, cy - _lineHeight / 2, size.width, _lineHeight),
          const Radius.circular(2),
        ),
        linePaint,
      );
    } else {
      final width = (size.width - _yinGap) / 2;
      for (var i = 0; i < 2; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              i * (width + _yinGap),
              cy - _lineHeight / 2,
              width,
              _lineHeight,
            ),
            const Radius.circular(2),
          ),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _YaoLinePainter oldDelegate) =>
      oldDelegate.yang != yang ||
      oldDelegate.color != color ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.glowOpacity != glowOpacity;
}
