import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tokens/ds_radius.dart';
import '../tokens/ds_shadow.dart';
import '../tokens/ds_spacing.dart';
import '../tokens/ds_theme_extension.dart';

class DSGlassPanel extends StatelessWidget {
  const DSGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DSSpacing.lg),
    this.radius = DSRadius.lg,
    this.color,
    this.border,
    this.shadow = DSShadow.panel,
    this.glow,
    this.enableBlur = false,
    this.blurSigma = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow> shadow;
  final BoxShadow? glow;
  final bool enableBlur;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final effectiveColor = color ?? ds.glass;
    final effectiveGlow = glow;
    final shadows = [?effectiveGlow, ...shadow];
    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: ds.hairline, width: .8),
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
