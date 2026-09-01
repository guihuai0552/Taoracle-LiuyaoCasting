import 'package:flutter/material.dart';

/// v1.0 · 阴影与辉光令牌 · **全部停用（无阴影原则）**。
///
/// Quiet Intelligence / 静默智能：层级靠色差（玄武岩黑底 × 深海军蓝卡）与
/// 发丝线表达，**不使用任何投影与辉光**（去塑料三原则：不厚重 / 不发光）。
///
/// 保留类与字段名以兼容存量引用（值全部为空列表），
/// 存量组件引用零改动即全局去阴影。
abstract final class DSShadow {
  /// 页面级漫射阴影（已停用）。
  static const List<BoxShadow> ambient = <BoxShadow>[];

  /// 面板级阴影（已停用）。
  static const List<BoxShadow> panel = <BoxShadow>[];

  /// 浮层阴影（已停用）。
  static const List<BoxShadow> overlay = <BoxShadow>[];

  /// 琥珀辉光（已停用）。
  static const List<BoxShadow> glowAmber = <BoxShadow>[];

  /// 青铜辉光（已停用）。
  static const List<BoxShadow> glowCeladon = <BoxShadow>[];

  /// 玉青辉光（已停用）。
  static const List<BoxShadow> glowJade = <BoxShadow>[];

  /// 朱砂辉光（已停用）。
  static const List<BoxShadow> glowCinnabar = <BoxShadow>[];
}
