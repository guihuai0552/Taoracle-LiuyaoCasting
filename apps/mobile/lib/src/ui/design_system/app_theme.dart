import 'package:flutter/material.dart';

import 'tokens/ds_colors.dart';
import 'tokens/ds_radius.dart';
import 'tokens/ds_spacing.dart';
import 'tokens/ds_typography.dart';

/// 构建「宣纸仪器 Paper Instrument」主题（浅色唯一主题，v0.8）。
///
/// 宣纸米白底 + 浓墨正文 + 传统矿物色信号（青瓷/黛蓝/朱砂/赭金）；
/// 无荧光、无发光 —— 质感来自纸与墨。夜观星历深底令牌见 [DSColorsNocturne]，
/// 供导出封面等 L2 高光场景。
/// token 全表见 docs/design-system-v0.8-paper-instrument.md。
ThemeData buildOrientalInstrumentTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final colors = ColorScheme.light(
    primary: DSColors.celadon,
    onPrimary: DSColors.moonWhite,
    primaryContainer: const Color(0xFFDCE8E2),
    onPrimaryContainer: DSColors.celadonDeep,
    secondary: DSColors.jade,
    onSecondary: DSColors.moonWhite,
    secondaryContainer: const Color(0xFFDBE5EC),
    onSecondaryContainer: DSColors.jade,
    error: DSColors.cinnabar,
    onError: Colors.white,
    surface: DSColors.surfaceRaised,
    onSurface: DSColors.textPrimary,
    surfaceContainerHighest: DSColors.glass,
    outline: DSColors.hairlineStrong,
    outlineVariant: DSColors.hairline,
    shadow: Colors.black,
  );

  final bodyTheme = base.textTheme.apply(
    bodyColor: DSColors.textPrimary,
    displayColor: DSColors.textPrimary,
    fontFamilyFallback: DSTypography.sansFallback,
  );

  // 2026-09-01 字体规范统一：全 App 以「道谕六爻」基准（sans 链）为唯一
  // 标题字体——serifFallback 在 Android 上无衬线可回退，导致双端与页面间
  // 字体漂移，故标题不再切衬线链，仅保留 w600→w700 的层级提升。
  TextStyle heading(TextStyle? source) =>
      (source ?? const TextStyle()).copyWith(
        color: DSColors.textPrimary,
        fontFamilyFallback: DSTypography.sansFallback,
        fontWeight: (source?.fontWeight ?? FontWeight.w600) == FontWeight.w600
            ? FontWeight.w700
            : source?.fontWeight,
      );

  return base.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: DSColors.background,
    canvasColor: DSColors.background,
    dividerColor: DSColors.hairlineStrong,
    textTheme: bodyTheme.copyWith(
      displayLarge: heading(bodyTheme.displayLarge),
      displayMedium: heading(bodyTheme.displayMedium),
      displaySmall: heading(bodyTheme.displaySmall),
      headlineLarge: heading(bodyTheme.headlineLarge),
      headlineMedium: heading(bodyTheme.headlineMedium),
      headlineSmall: heading(bodyTheme.headlineSmall),
      titleLarge: heading(bodyTheme.titleLarge),
      titleMedium: heading(bodyTheme.titleMedium),
      titleSmall: heading(bodyTheme.titleSmall),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: DSColors.textPrimary,
      // 状态栏深色图标由 app.dart 的 AnnotatedRegion 全局保障；
      // Flutter 3.44 起 AppBarTheme 不再有 systemUiOverlayStyle 参数。
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: DSTypography.displayLight(
        fontSize: 20,
        weight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: DSColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.lg),
        side: const BorderSide(color: DSColors.hairlineStrong, width: .8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DSColors.celadon,
        foregroundColor: DSColors.moonWhite,
        disabledBackgroundColor: DSColors.textFaint,
        disabledForegroundColor: DSColors.surface,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: .4,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DSColors.textPrimary,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: DSColors.hairlineStrong, width: 1.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DSColors.celadonDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DSColors.surface,
      hintStyle: const TextStyle(color: DSColors.textFaint),
      labelStyle: const TextStyle(color: DSColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: const BorderSide(color: DSColors.hairlineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: const BorderSide(color: DSColors.hairlineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: const BorderSide(color: DSColors.celadon, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DSColors.glassStrong.withValues(alpha: .96),
      surfaceTintColor: Colors.transparent,
      indicatorColor: DSColors.celadon.withValues(alpha: .14),
      elevation: 0,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? DSColors.celadonDeep
              : DSColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? DSColors.celadonDeep
              : DSColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: DSColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: DSColors.glassStrong,
      showDragHandle: true,
      dragHandleColor: DSColors.textMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DSRadius.sheetTop),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DSColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.sheetTop),
        side: const BorderSide(color: DSColors.hairlineStrong),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: DSColors.hairlineStrong,
      thickness: .8,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: DSColors.glassWeak.withValues(alpha: .06),
      selectedColor: DSColors.celadon.withValues(alpha: .16),
      side: const BorderSide(color: DSColors.hairlineStrong),
      labelStyle: const TextStyle(color: DSColors.textPrimary, fontSize: 12),
      secondaryLabelStyle: const TextStyle(
        color: DSColors.moonWhite,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      checkmarkColor: DSColors.celadonDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? DSColors.celadonDeep
            : DSColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? DSColors.celadonDim.withValues(alpha: .7)
            : DSColors.paperEdge,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DSColors.celadon,
      linearTrackColor: DSColors.paperEdge,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: DSColors.textPrimary,
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      textStyle: const TextStyle(color: DSColors.moonWhite, fontSize: 11),
    ),
  );
}

/// 宣纸底背景：米白基座沉入旧纸边缘（v0.1 纸纹语言回归，去深色渐变）。
/// 安静、无装饰，让卦面内容成为唯一主角；L2 场景另用 [DSColors.bgDeep]。
class DSInstrumentBackground extends StatelessWidget {
  const DSInstrumentBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [DSColors.background, DSColors.bgDeep],
        stops: [0, .9],
      ),
    ),
    child: child,
  );
}
