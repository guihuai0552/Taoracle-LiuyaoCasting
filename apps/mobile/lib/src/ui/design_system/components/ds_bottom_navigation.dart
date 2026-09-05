import 'package:flutter/material.dart';

import '../tokens/ds_radius.dart';
import '../tokens/ds_spacing.dart';
import '../tokens/ds_theme_extension.dart';
import '../tokens/ds_typography.dart';
import 'liuyao_icon.dart';

class DSBottomNavigation extends StatelessWidget {
  const DSBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<DSDestinationItem> destinations;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      decoration: BoxDecoration(
        color: ds.glassStrong,
        border: Border(top: BorderSide(color: ds.hairlineStrong, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _DestinationButton(
                    item: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DSDestinationItem {
  const DSDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.itemKey,
    this.svgIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Key? itemKey;
  final LiuyaoIconType? svgIcon;
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DSDestinationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return InkWell(
      key: item.itemKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(DSRadius.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: selected ? 20 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: ds.celadon,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: DSSpacing.xs),
          if (item.svgIcon case final svg?)
            LiuyaoIcon(
              svg,
              size: 22,
              selected: selected,
              color: ds.textMuted,
              selectedColor: ds.celadonDeep,
            )
          else
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 22,
              color: selected ? ds.celadonDeep : ds.textMuted,
            ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontFamilyFallback: DSTypography.sansFallback,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? ds.textPrimary : ds.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
