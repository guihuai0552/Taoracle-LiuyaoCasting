import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_spacing.dart';
import '../tokens/ds_typography.dart';
import 'liuyao_icon.dart';

/// v1.0 Quiet Intelligence · 底部导航（自绘，替代 Material NavigationBar）。
///
/// 纯白玻璃浮起 + 发丝分隔线，选中项为朱红短横线 + 浓墨字，
/// 未选中为弱文本；图标优先使用 v1.0 SVG 细线图标集（[LiuyaoIcon]），
/// 未提供 svgIcon 时回退 Material 线性图标。
/// 结构：高度 64 + 顶部 1px 发丝线；选中指示为 20px 短横线（朱红），
/// 不用 Material 的胶囊指示器。
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
    return Container(
      decoration: const BoxDecoration(
        color: DSColors.glassStrong,
        border: Border(
          top: BorderSide(color: DSColors.hairlineStrong, width: 1),
        ),
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

  /// v1.0 SVG 细线图标；提供时优先于 [icon] / [selectedIcon] 渲染。
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
    return InkWell(
      key: item.itemKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(DSRadius.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 选中指示：青瓷短横线。
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: selected ? 20 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: DSColors.celadon,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: DSSpacing.xs),
          if (item.svgIcon case final svg?)
            LiuyaoIcon(
              svg,
              size: 22,
              selected: selected,
              color: DSColors.textMuted,
              selectedColor: DSColors.celadonDeep,
            )
          else
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 22,
              color: selected ? DSColors.celadonDeep : DSColors.textMuted,
            ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontFamilyFallback: DSTypography.sansFallback,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? DSColors.textPrimary : DSColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
