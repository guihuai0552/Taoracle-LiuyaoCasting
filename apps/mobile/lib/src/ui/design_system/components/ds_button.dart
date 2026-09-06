import 'package:flutter/material.dart';

import '../tokens/ds_radius.dart';
import '../tokens/ds_shadow.dart';
import '../tokens/ds_spacing.dart';
import '../tokens/ds_theme_extension.dart';

enum DSButtonVariant { primary, secondary, ghost, ritual }

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
    final ds = context.ds;
    final background = switch (variant) {
      DSButtonVariant.primary => ds.celadon,
      DSButtonVariant.secondary => ds.glassWeak,
      DSButtonVariant.ghost => Colors.transparent,
      DSButtonVariant.ritual => ds.glass,
    };
    final foreground = switch (variant) {
      DSButtonVariant.primary => ds.background,
      DSButtonVariant.secondary => ds.textPrimary,
      DSButtonVariant.ghost => ds.textSecondary,
      DSButtonVariant.ritual => ds.celadonDeep,
    };
    final border = switch (variant) {
      DSButtonVariant.primary => Border.all(
        color: Colors.transparent,
        width: 0,
      ),
      DSButtonVariant.secondary => Border.all(color: ds.metalLine, width: 1),
      DSButtonVariant.ghost => Border.all(color: Colors.transparent, width: 0),
      DSButtonVariant.ritual => Border.all(color: ds.metalLine, width: 1),
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
