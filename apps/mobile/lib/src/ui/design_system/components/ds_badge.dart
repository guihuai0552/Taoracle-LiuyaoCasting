import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';

/// 徽标语气：决定前景/背景配色。
enum DSBadgeTone { celadon, jade, cinnabar, coldBlue, neutral }

/// 徽标：用于动爻、世应、六神、旺衰、空亡、月建日辰、结果倾向等短标签。
///
/// 纯展示组件；[label] 由调用方传入，不参与任何业务判断。
class DSBadge extends StatelessWidget {
  const DSBadge({
    super.key,
    required this.label,
    this.tone = DSBadgeTone.neutral,
    this.filled = false,
    this.icon,
    this.dense = false,
  });

  final String label;
  final DSBadgeTone tone;
  final bool filled;
  final IconData? icon;
  final bool dense;

  static Color _foreground(DSBadgeTone tone) => switch (tone) {
    DSBadgeTone.celadon => DSColors.celadonDeep,
    DSBadgeTone.jade => DSColors.jade,
    DSBadgeTone.cinnabar => DSColors.cinnabarSoft,
    DSBadgeTone.coldBlue => DSColors.coldBlue,
    DSBadgeTone.neutral => DSColors.textSecondary,
  };

  static Color _background(DSBadgeTone tone) => switch (tone) {
    DSBadgeTone.celadon => DSColors.celadon.withValues(alpha: .16),
    DSBadgeTone.jade => DSColors.jade.withValues(alpha: .16),
    DSBadgeTone.cinnabar => DSColors.cinnabar.withValues(alpha: .18),
    DSBadgeTone.coldBlue => DSColors.coldBlue.withValues(alpha: .14),
    DSBadgeTone.neutral => DSColors.moonWhite.withValues(alpha: .08),
  };

  @override
  Widget build(BuildContext context) {
    final fg = _foreground(tone);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: filled ? fg : _background(tone),
        borderRadius: BorderRadius.circular(DSRadius.pill),
        border: filled
            ? null
            : Border.all(color: fg.withValues(alpha: .38), width: .8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: dense ? 10 : 12,
              color: filled ? DSColors.background : fg,
            ),
            SizedBox(width: dense ? 2 : 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? DSColors.background : fg,
              fontSize: dense ? 9 : 10,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
