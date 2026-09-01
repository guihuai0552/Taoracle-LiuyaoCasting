import 'package:flutter/material.dart';

/// 当代文人极简 · 字体令牌（v0.3 Linear 式字阶）。
///
/// 四级字重（400/500/600/700）+ 八级字号（10–28px）。
/// 标题衬线（书卷气质），正文无衬线（可读性优先）。
/// 「字重即层级」：同一区块只用两种字重，不用字号+字重双重堆砌。
abstract final class DSTypography {
  /// 现代无衬线回退链（正文）。
  static const List<String> sansFallback = [
    'PingFang SC',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'sans-serif',
  ];

  /// 衬线回退链（标题、卦名）。
  static const List<String> serifFallback = [
    'Songti SC',
    'Noto Serif CJK SC',
    'Noto Serif SC',
    'STSong',
    'serif',
  ];

  /// 等宽回退链（参数、读数、元数据）—— v1.0 升级：Space Mono / Inconsolata 优先，
  /// 系统等宽字体兜底（离线场景不打包字体文件时仍可用）。
  static const List<String> monoFallback = [
    'Space Mono',
    'Inconsolata',
    'SFMono-Regular',
    'Menlo',
    'Monaco',
    'Consolas',
    'monospace',
  ];

  // —— 字重（Linear 四级，禁用 w800/w900）——
  static const FontWeight normal = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // —— 字号（八级）——
  /// 10 —— 极小标签、神煞缩写。
  static const double xs = 10;

  /// 12 —— 辅助说明、表头。
  static const double sm = 12;

  /// 14 —— 正文默认。
  static const double base = 14;

  /// 15 —— 表格内容、列表项。
  static const double md = 15;

  /// 16 —— 重要正文、按钮文字。
  static const double lg = 16;

  /// 18 —— 小标题、卦名。
  static const double xl = 18;

  /// 22 —— 区块标题。
  static const double xxl = 22;

  /// 28 —— 页面大标题、卦名（大屏）。
  static const double xxxl = 28;

  /// 衬线标题样式快捷构造。
  ///
  /// ⚠️ 2026-09-01 字体规范：全 App 标题统一走 sans 基准（displayLight /
  /// body），此构造仅保留给「道谕宋」印章类特殊场景之外的极少数衬线
  /// 需求——Android 无衬线可回退，常规标题禁用（会双端漂移）。
  static TextStyle serif({
    double fontSize = 18,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.25,
  }) => TextStyle(
    fontFamilyFallback: serifFallback,
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    height: height,
  );

  /// 正文样式快捷构造。
  static TextStyle body({
    double fontSize = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.5,
  }) => TextStyle(
    fontFamilyFallback: sansFallback,
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    height: height,
  );

  /// 表格行样式：15px + w500 + 行高 1.375（≈21px 行高）。
  static TextStyle table({Color? color}) => TextStyle(
    fontFamilyFallback: sansFallback,
    fontSize: md,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.375,
  );

  /// 表头样式：12px + w500 + 次级文本。
  static TextStyle tableHeader({Color? color}) => TextStyle(
    fontFamilyFallback: sansFallback,
    fontSize: sm,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.375,
  );

  // —— v1.0 Quiet Intelligence 新增构造 ————————————————

  /// 等宽元数据样式（v1.0 §3.1）：干支、纳甲、计算轨迹、时间戳、版本号。
  /// Monospaced Metadata——专业工具的元数据语言。
  static TextStyle mono({
    double fontSize = 12,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.5,
    double? letterSpacing,
  }) => TextStyle(
    fontFamilyFallback: monoFallback,
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// 全大写标签样式（v1.0 §3.2 Overline）：分类 chips、状态标记、关键词。
  /// 等宽字体 + 宽字距（1.2px）+ 10px。
  static TextStyle overline({Color? color, double fontSize = 10}) => TextStyle(
    fontFamilyFallback: monoFallback,
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.4,
    letterSpacing: 1.2,
  );

  /// 细体标题样式（v1.0 §3.1 主标题）：现代无衬线 w300，宽松字距。
  /// 页面标题、卦名、区块标题的「安静」表达。
  static TextStyle displayLight({
    double fontSize = 24,
    FontWeight weight = FontWeight.w300,
    Color? color,
    double height = 1.3,
  }) => TextStyle(
    fontFamilyFallback: sansFallback,
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: .3,
  );
}
