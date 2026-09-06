import 'package:flutter/material.dart';

import '../tokens/ds_radius.dart';
import '../tokens/ds_theme_extension.dart';

enum DSBadgeTone { celadon, jade, cinnabar, coldBlue, neutral }

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

  static Color _foreground(DSColorsScheme ds, DSBadgeTone tone) =>
      switch (tone) {
        DSBadgeTone.celadon => ds.celadonDeep,
        DSBadgeTone.jade => ds.jade,
        DSBadgeTone.cinnabar => ds.cinnabarSoft,
        DSBadgeTone.coldBlue => ds.coldBlue,
        DSBadgeTone.neutral => ds.textSecondary,
      };

  static Color _background(DSColorsScheme ds, DSBadgeTone tone) =>
      switch (tone) {
        DSBadgeTone.celadon => ds.celadon.withValues(alpha: .16),
        DSBadgeTone.jade => ds.jade.withValues(alpha: .16),
        DSBadgeTone.cinnabar => ds.cinnabar.withValues(alpha: .18),
        DSBadgeTone.coldBlue => ds.coldBlue.withValues(alpha: .14),
        DSBadgeTone.neutral => ds.moonWhite.withValues(alpha: .08),
      };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final fg = _foreground(ds, tone);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: filled ? fg : _background(ds, tone),
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
              color: filled ? ds.background : fg,
            ),
            SizedBox(width: dense ? 2 : 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? ds.background : fg,
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
