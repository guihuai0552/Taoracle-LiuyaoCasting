import 'package:flutter/material.dart';

import '../tokens/ds_motion.dart';

/// 淡入 + 轻微上浮入场。
///
/// 页面区块、卡片、结果面板的默认入场动效。可指定 [delay] 做依次浮现。
class DSReveal extends StatelessWidget {
  const DSReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = DSMotion.slow,
    this.distance = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start.clamp(0.0, 1.0), 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, distance * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// 淡入 + 轻微缩放入场（用于卦面、弹层内容）。
class DSScaleIn extends StatelessWidget {
  const DSScaleIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = DSMotion.slow,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start.clamp(0.0, 1.0), 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: .97 + .03 * value,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// 依次揭示：为子项施加递增延迟的淡入 + 上浮。
///
/// 用于六爻自下而上依次出现、列表卡片依次浮现。子项在竖直方向排列。
class DSStaggerReveal extends StatelessWidget {
  const DSStaggerReveal({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 90),
    this.duration = DSMotion.slow,
    this.distance = 12,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final Duration stagger;
  final Duration duration;
  final double distance;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          DSReveal(
            delay: stagger * i,
            duration: duration,
            distance: distance,
            child: children[i],
          ),
      ],
    );
  }
}
