import 'package:flutter/material.dart';

import '../tokens/ds_radius.dart';
import '../tokens/ds_theme_extension.dart';
import '../tokens/ds_typography.dart';

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
  final Key? keyOverride;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      key: keyOverride,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ds.glassWeak,
        borderRadius: BorderRadius.circular(DSRadius.sm + 3),
        border: Border.all(color: ds.hairline, width: 1),
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
                        ? ds.surfaceRaised
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    border: selected.contains(segment.value)
                        ? Border.all(color: ds.hairlineStrong, width: 1)
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
                            ? ds.celadonDeep
                            : ds.textMuted,
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
                              ? ds.textPrimary
                              : ds.textMuted,
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
