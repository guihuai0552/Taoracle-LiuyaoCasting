import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_typography.dart';

/// 当代文人极简 · 分段控件（自绘，替代 Material SegmentedButton）。
///
/// 弱底槽 + 选中项为纸白抬升块 + 1px 发丝边，青瓷选中文字。
/// 用途：起卦模式切换（手动/自动铜钱/时刻起卦）等 2–4 段场景。
class DSSegmentedControl<T> extends StatelessWidget {
  const DSSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.keyOverride,
  });

  final List<DSSegmentItem<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// 外部指定整体 key（保留既有测试 key）。
  final Key? keyOverride;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: keyOverride,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DSColors.glassWeak,
        borderRadius: BorderRadius.circular(DSRadius.sm + 3),
        border: Border.all(color: DSColors.hairline, width: 1),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelectionChanged?.call({segment.value}),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected.contains(segment.value)
                        ? DSColors.surfaceRaised
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    border: selected.contains(segment.value)
                        ? Border.all(color: DSColors.hairlineStrong, width: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        segment.icon,
                        size: 16,
                        color: selected.contains(segment.value)
                            ? DSColors.celadonDeep
                            : DSColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        segment.label,
                        style: TextStyle(
                          fontFamilyFallback: DSTypography.sansFallback,
                          fontSize: 13,
                          fontWeight: selected.contains(segment.value)
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected.contains(segment.value)
                              ? DSColors.textPrimary
                              : DSColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DSSegmentItem<T> {
  const DSSegmentItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}
