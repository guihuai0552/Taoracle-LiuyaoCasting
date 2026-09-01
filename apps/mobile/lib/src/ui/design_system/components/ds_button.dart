import 'package:flutter/material.dart';

import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadow.dart';
import '../tokens/ds_spacing.dart';

/// 按钮分级：主操作 / 次级 / 幽灵 / 仪式。
enum DSButtonVariant { primary, secondary, ghost, ritual }

/// 现代东方术数仪器 · 按钮。
///
/// - [DSButtonVariant.primary]：开始起卦、生成解读等主操作。
/// - [DSButtonVariant.secondary]：查看详情、保存等次级操作。
/// - [DSButtonVariant.ghost]：返回、更多等轻操作。
/// - [DSButtonVariant.ritual]：摇卦、重新起卦等仪式性动作（青铜辉光 + 刻线）。
class DSButton extends StatelessWidget {
  const DSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = DSButtonVariant.primary,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DSButtonVariant variant;
  final bool loading;
  final bool expand;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final background = switch (variant) {
      DSButtonVariant.primary => DSColors.celadon,
      DSButtonVariant.secondary => DSColors.glassWeak,
      DSButtonVariant.ghost => Colors.transparent,
      DSButtonVariant.ritual => DSColors.glass,
    };
    final foreground = switch (variant) {
      DSButtonVariant.primary => DSColors.background,
      DSButtonVariant.secondary => DSColors.textPrimary,
      DSButtonVariant.ghost => DSColors.textSecondary,
      DSButtonVariant.ritual => DSColors.celadonDeep,
    };
    final border = switch (variant) {
      DSButtonVariant.primary => Border.all(
        color: Colors.transparent,
        width: 0,
      ),
      DSButtonVariant.secondary => Border.all(
        color: DSColors.metalLine,
        width: 1,
      ),
      DSButtonVariant.ghost => Border.all(color: Colors.transparent, width: 0),
      DSButtonVariant.ritual => Border.all(color: DSColors.metalLine, width: 1),
    };
    final shadow = switch (variant) {
      DSButtonVariant.ritual => DSShadow.glowCeladon,
      DSButtonVariant.primary => DSShadow.panel,
      _ => const <BoxShadow>[],
    };

    return Semantics(
      button: true,
      enabled: _enabled,
      child: Opacity(
        opacity: _enabled ? 1 : .42,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(
                variant == DSButtonVariant.ritual ? DSRadius.md : DSRadius.sm,
              ),
              border: border,
              boxShadow: shadow,
            ),
            child: InkWell(
              onTap: _enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(DSRadius.sm),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    else if (icon != null) ...[
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: DSSpacing.xs),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
