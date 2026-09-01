import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_motion.dart';
import '../tokens/ds_radius.dart';

/// 辉光脉冲 · **已停用（v1.0 无阴影/无辉光原则）**。
///
/// Quiet Intelligence：动效克制、无发光装饰（去塑料三原则）。
/// 保留类与参数以兼容存量引用（demo 页），现在仅直通子组件。
class DSGlowPulse extends StatelessWidget {
  const DSGlowPulse({
    super.key,
    required this.child,
    this.glowColor = DSColors.glowAmber,
    this.duration = DSMotion.ritual,
    this.radius = DSRadius.sm,
  });

  final Widget child;
  final Color glowColor;
  final Duration duration;
  final double radius;

  @override
  Widget build(BuildContext context) => child;
}
