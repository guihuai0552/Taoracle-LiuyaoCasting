import 'package:flutter/material.dart';

/// 统一的「道谕六爻」品牌标题。
///
/// 以档案页（案例库）样式为唯一基准：
/// `headlineLarge`（displayLight 家族 · 24px · 主题墨色）
/// + `w600` + `letterSpacing: -1`。
///
/// 六爻页 / 档案页 / 设置页 / 卦面详情 AppBar 均须使用本组件，
/// 禁止各自手写样式导致字体漂移。
class DaoyuBrandTitle extends StatelessWidget {
  const DaoyuBrandTitle({super.key, this.keyOverride, this.fontSize});

  /// 供测试与调用方定位；不传则无 key。
  final Key? keyOverride;

  /// 特殊容器（如 AppBar）可覆写字号；字体家族 / 字重 / 字距不可覆写。
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineLarge;
    return Text(
      '道谕六爻',
      key: keyOverride,
      style: base?.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
      ),
    );
  }
}
