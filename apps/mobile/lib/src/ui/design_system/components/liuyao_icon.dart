import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/ds_theme_extension.dart';

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

  final String fileName;

  String get path => 'assets/icons/$fileName';
}

class LiuyaoIcon extends StatelessWidget {
  const LiuyaoIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.selectedColor,
    this.selected = false,
  });

  final LiuyaoIconType icon;
  final double size;
  final Color? color;
  final Color? selectedColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final resolvedColor = color ?? ds.textMuted;
    final resolvedSelected = selectedColor ?? ds.celadon;
    return SvgPicture.asset(
      icon.path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        selected ? resolvedSelected : resolvedColor,
        BlendMode.srcIn,
      ),
    );
  }
}
