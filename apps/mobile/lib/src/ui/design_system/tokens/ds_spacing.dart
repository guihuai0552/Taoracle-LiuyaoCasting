/// 现代东方术数仪器 · 间距令牌。
///
/// 基于 4pt 基准系统，扩展至 48pt，覆盖精密仪器布局所需的最小节奏。
abstract final class DSSpacing {
  /// 2 —— 刻线级。
  static const double xxs = 2;

  /// 4 —— 最小间隙。
  static const double xs = 4;

  /// 8 —— 紧凑间隙。
  static const double sm = 8;

  /// 12 —— 常规块内间隙。
  static const double md = 12;

  /// 16 —— 块间/卡片内边距。
  static const double lg = 16;

  /// 24 —— 区块外间距。
  static const double xl = 24;

  /// 32 —— 大区块间距。
  static const double xxl = 32;

  /// 48 —— 页面级留白。
  static const double xxxl = 48;
}
