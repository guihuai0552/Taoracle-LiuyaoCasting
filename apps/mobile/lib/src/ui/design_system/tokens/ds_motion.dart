import 'package:flutter/material.dart';

/// 现代东方术数仪器 · 动效令牌。
///
/// 原则：慢一点、稳一点，像仪器启动。不做花哨弹跳，发光与 shimmer 克制。
/// 关键动作（起卦、成卦、变卦、解读生成）使用更长、更庄重的 ritual 节奏。
abstract final class DSMotion {
  // —— 时长 ——
  /// 160ms：微交互、hover。
  static const Duration fast = Duration(milliseconds: 160);

  /// 280ms：常规转场、状态切换。
  static const Duration normal = Duration(milliseconds: 280);

  /// 560ms：入场、成组动画。
  static const Duration slow = Duration(milliseconds: 560);

  /// 1200ms：仪式性动画（成卦、变卦、扫描线）。
  static const Duration ritual = Duration(milliseconds: 1200);

  // —— 曲线 ——
  /// 标准出场（大多数交互）。
  static const Curve standard = Curves.easeOutCubic;

  /// 强调出场（大面板、卦面浮现）。
  static const Curve emphasize = Curves.easeOutQuart;

  /// 入场曲线。
  static const Curve entrance = Curves.easeOutCubic;

  /// 退场曲线。
  static const Curve exit = Curves.easeInCubic;
}
