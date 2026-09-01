import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadow.dart';
import '../tokens/ds_spacing.dart';

/// 玻璃面板：半透明背景 + 细线边框 + 可选毛玻璃模糊 + 低透明度叠层。
///
/// 用于卦盘容器、信息浮层、解读摘要卡、弹层背景。默认关闭
/// [enableBlur]（BackdropFilter 在列表滚动中成本较高），需要时显式开启。
class DSGlassPanel extends StatelessWidget {
  const DSGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DSSpacing.lg),
    this.radius = DSRadius.lg,
    this.color = DSColors.glass,
    this.border,
    this.shadow = DSShadow.panel,
    this.glow,
    this.enableBlur = false,
    this.blurSigma = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final BoxBorder? border;
  final List<BoxShadow> shadow;
  final BoxShadow? glow;
  final bool enableBlur;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = glow;
    final shadows = [?effectiveGlow, ...shadow];
    final decoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border:
          border ??
          const Border.fromBorderSide(
            BorderSide(color: DSColors.hairline, width: .8),
          ),
      boxShadow: shadows,
    );

    final panel = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (!enableBlur) return panel;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: panel,
      ),
    );
  }
}
