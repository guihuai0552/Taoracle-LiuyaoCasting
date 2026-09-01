import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/ds_colors.dart';

/// v1.1 细线图标集（道谕六爻 · 宣纸卡片）。
///
/// 规范：24px 画布 · stroke 1.5 · 圆角 2 · 线性优先 · 不用于装饰。
/// 颜色：默认弱文本 `#8B8B87`；选中态朱红 `#A9282D`（线框图主强调）。
///
/// 用法：
/// ```dart
/// LiuyaoIcon(LiuyaoIconType.archive)                       // 中性灰
/// LiuyaoIcon(LiuyaoIconType.archive, selected: true)       // 朱红选中
/// ```
enum LiuyaoIconType {
  back._('icons-back.svg'),
  export._('icons-export.svg'),
  more._('icons-more.svg'),
  search._('icons-search.svg'),
  filter._('icons-filter.svg'),
  review._('icons-review.svg'),
  delete._('icons-delete.svg'),
  settings._('icons-settings.svg'),
  archive._('icons-archive.svg'),
  archiveBox._('icons-archive-box.svg'),
  divination._('icons-divination.svg'),
  home._('icons-home.svg'),
  calendar._('icons-calendar.svg');

  const LiuyaoIconType._(this.fileName);

  /// assets/icons/ 下的文件名。
  final String fileName;

  /// 完整 asset 路径。
  String get path => 'assets/icons/$fileName';
}

/// v1.0 细线图标组件：SVG 渲染 + 信号色切换。
class LiuyaoIcon extends StatelessWidget {
  const LiuyaoIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color = DSColors.textMuted,
    this.selectedColor = DSColors.celadon,
    this.selected = false,
  });

  final LiuyaoIconType icon;

  /// 图标尺寸：24（标准）/ 16（紧凑）。
  final double size;

  /// 默认色（中性灰）。
  final Color color;

  /// 选中色（蓝灰，仅关键信息）。
  final Color selectedColor;

  final bool selected;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    icon.path,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(
      selected ? selectedColor : color,
      BlendMode.srcIn,
    ),
  );
}
