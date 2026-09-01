/// 现代东方术数仪器 · 透明度令牌。
///
/// 用受控的透明度叠加替代厚重的实色分层，配合玻璃层形成层次。
abstract final class DSOpacity {
  /// 6%：背景装饰、极淡网格。
  static const double faint = .06;

  /// 14%：次级装饰、hover 底。
  static const double subtle = .14;

  /// 30%：遮罩、弱边框。
  static const double veil = .30;

  /// 62%：强遮罩、玻璃层下压暗。
  static const double strong = .62;
}
