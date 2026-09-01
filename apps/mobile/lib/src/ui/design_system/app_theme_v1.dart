import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens/ds_colors.dart';
import 'tokens/ds_colors_v1.dart';
import 'tokens/ds_radius.dart';
import 'tokens/ds_spacing.dart';
import 'tokens/ds_typography.dart';

/// 构建「Quiet Intelligence / 静默智能」主题（v1.0 · 浅色默认）。
///
/// 米白 `#E7E7E0` 底 × 玄武岩黑 `#1E1E1E` 字 × 蓝灰 `#6E7C89` 信号配给制；
/// 标题细体（w300）、等宽元数据、发丝线分隔——去塑料三原则
/// （不光滑 / 不厚重 / 不装饰）。真源规范：design-system-v1.0.md §2 §3 §5 §10.2。
///
/// 暗色版本见 [buildQuietIntelligenceNocturne]（§10.1：玄武岩黑底 + 深海军蓝卡片）。
ThemeData buildQuietIntelligenceTheme() => _buildQuietIntelligence(dark: false);

/// 构建「Quiet Intelligence」暗色主题（Nocturne）。
///
/// 玄武岩黑 `#1E1E1E` 主背景 + 深海军蓝 `#131936` 卡片 + 米白 `#E7E7E0` 文字。
ThemeData buildQuietIntelligenceNocturne() =>
    _buildQuietIntelligence(dark: true);

ThemeData _buildQuietIntelligence({required bool dark}) {
  final base = dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);

  // —— 模式化取值（§10.1 / §10.2）——
  final bg = dark ? DSColorsV1.nightBackground : DSColorsV1.background;
  final surface = dark ? DSColorsV1.nightSurface : DSColorsV1.surfaceLight;
  final surfaceSunken = dark
      ? DSColorsV1.nightSurfaceRaised
      : DSColorsV1.surfaceLightSunken;
  final glass = dark ? DSColorsV1.glassNight : DSColorsV1.glassLight;
  final textPrimary = dark
      ? DSColorsV1.textPrimaryNight
      : DSColorsV1.textPrimary;
  final textSecondary = dark
      ? DSColorsV1.textSecondaryNight
      : DSColorsV1.textSecondary;
  final textMuted = dark ? DSColorsV1.textMutedNight : DSColorsV1.textMuted;
  final textFaint = dark ? DSColorsV1.textFaintNight : DSColorsV1.textFaint;
  final hairline = dark ? DSColorsV1.hairlineNight : DSColorsV1.hairline;
  final hairlineStrong = dark
      ? DSColorsV1.hairlineNight
      : DSColorsV1.hairlineStrong;
  // 深容器（primaryContainer = 深海军蓝）上永远用米白反白字，保证对比度。
  final onDarkContainer = DSColorsV1.background;

  final colors = (dark ? ColorScheme.dark : ColorScheme.light)(
    primary: DSColorsV1.accent,
    onPrimary: onDarkContainer,
    primaryContainer: DSColorsV1.primaryVariant,
    onPrimaryContainer: onDarkContainer,
    secondary: DSColorsV1.secondary,
    onSecondary: onDarkContainer,
    secondaryContainer: surfaceSunken,
    onSecondaryContainer: textSecondary,
    error: DSColorsV1.warning,
    onError: onDarkContainer,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: surfaceSunken,
    outline: hairlineStrong,
    outlineVariant: hairline,
    shadow: DSColorsV1.primary,
  );

  final bodyTheme = base.textTheme.apply(
    bodyColor: textPrimary,
    displayColor: textPrimary,
    fontFamilyFallback: DSTypography.sansFallback,
  );

  return base.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: hairlineStrong,
    textTheme: bodyTheme.copyWith(
      // v1.0 §3.1：主标题现代无衬线细体（w300），不用衬线粗体。
      displayLarge: DSTypography.displayLight(
        fontSize: 32,
        color: textPrimary,
        height: 1.2,
      ),
      displayMedium: DSTypography.displayLight(
        fontSize: 28,
        color: textPrimary,
        height: 1.2,
      ),
      displaySmall: DSTypography.displayLight(
        fontSize: 24,
        color: textPrimary,
        height: 1.3,
      ),
      headlineLarge: DSTypography.displayLight(
        fontSize: 24,
        color: textPrimary,
        height: 1.3,
      ),
      headlineMedium: DSTypography.displayLight(
        fontSize: 20,
        color: textPrimary,
        height: 1.4,
      ),
      headlineSmall: DSTypography.displayLight(
        fontSize: 18,
        color: textPrimary,
        height: 1.4,
      ),
      titleLarge: DSTypography.body(
        fontSize: 18,
        weight: FontWeight.w400,
        color: textPrimary,
        height: 1.4,
      ),
      titleMedium: DSTypography.body(
        fontSize: 16,
        weight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: DSTypography.body(
        fontSize: 14,
        weight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: DSTypography.body(
        fontSize: 14,
        weight: FontWeight.w400,
        color: textPrimary,
        height: 1.6,
      ),
      bodyMedium: DSTypography.body(
        fontSize: 14,
        weight: FontWeight.w400,
        color: textSecondary,
        height: 1.6,
      ),
      bodySmall: DSTypography.body(
        fontSize: 12,
        weight: FontWeight.w400,
        color: textMuted,
        height: 1.5,
      ),
      // v1.0 §3.2 Overline：等宽 + 宽字距 + 全大写。
      labelLarge: DSTypography.overline(color: textSecondary, fontSize: 11),
      labelMedium: DSTypography.overline(color: textMuted),
      labelSmall: DSTypography.overline(color: textFaint, fontSize: 9),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: DSTypography.displayLight(
        fontSize: 20,
        color: textPrimary,
        height: 1.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.lg),
        side: BorderSide(color: hairline, width: .5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DSColorsV1.accent,
        foregroundColor: onDarkContainer,
        disabledBackgroundColor: textFaint,
        disabledForegroundColor: surfaceSunken,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: .4,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? textPrimary : DSColorsV1.accentDeep,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: hairlineStrong, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: dark ? DSColorsV1.accent : DSColorsV1.accentDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceSunken,
      hintStyle: TextStyle(color: textFaint),
      labelStyle: TextStyle(color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.sm),
        borderSide: BorderSide(color: hairline, width: .5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.sm),
        borderSide: BorderSide(color: hairline, width: .5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.sm),
        borderSide: const BorderSide(color: DSColorsV1.accent, width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: glass,
      surfaceTintColor: Colors.transparent,
      indicatorColor: DSColorsV1.glowAccentStrong,
      elevation: 0,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? DSColorsV1.accent
              : textMuted,
        ),
      ),
      // v1.0 §5.6：文字标签等宽 + 全大写 + 10px。
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => DSTypography.overline(
          color: states.contains(WidgetState.selected)
              ? DSColorsV1.accent
              : textMuted,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: glass,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: glass,
      showDragHandle: true,
      dragHandleColor: textMuted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DSRadius.sheetTop),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: glass,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.sheetTop),
        side: BorderSide(color: hairline, width: .5),
      ),
    ),
    dividerTheme: DividerThemeData(color: hairline, thickness: .5, space: 1),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: surfaceSunken,
      selectedColor: DSColorsV1.glowAccentStrong,
      side: BorderSide(color: hairline, width: .5),
      labelStyle: TextStyle(color: textPrimary, fontSize: 12),
      secondaryLabelStyle: TextStyle(
        color: onDarkContainer,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      checkmarkColor: DSColorsV1.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? DSColorsV1.accent
            : textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? DSColorsV1.glowAccentStrong
            : surfaceSunken,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DSColorsV1.accent,
      linearTrackColor: DSColorsV1.secondary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: DSColorsV1.primary,
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      textStyle: const TextStyle(color: DSColorsV1.background, fontSize: 11),
    ),
  );
}

/// v1.0 安静底（浅色）：纯米白，无渐变、无装饰——去塑料三原则。
/// 替代 v0.8 [DSInstrumentBackground] 的宣纸渐变；L2 高光层另行处理。
class DSQuietBackground extends StatelessWidget {
  const DSQuietBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: DSColorsV1.background, child: child);
}

/// v1.0 安静底（暗色）：玄武岩黑。
class DSQuietBackgroundNight extends StatelessWidget {
  const DSQuietBackgroundNight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: DSColorsV1.nightBackground, child: child);
}

/// 构建「道谕六爻」浅色朱红主题（当前生产默认，依照线框图还原）。
///
/// 暖白 `#F3F2EF` 底 × 纯白卡片 × 朱红主强调 `#A9282D` × 棕金辅助 `#AE8648`，
/// 全部经 [DSColors] 门面取色。视觉真源：
/// 仓库根目录的 `wireframe-preview-approved.html`（本地设计预览，不入库）。
///
/// 与 Nocturne 暗色的差异集中在色板与信号强调；字体、圆角、间距、组件
/// 结构与 v1.0 设计系统保持一致（标题细体、等宽元数据、发丝线分隔）。
ThemeData buildDaoyuTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final colors = ColorScheme.light(
    primary: DSColors.celadon,
    onPrimary: DSColors.moonWhite,
    primaryContainer: DSColors.glowCeladon,
    onPrimaryContainer: DSColors.celadonDeep,
    secondary: DSColors.jade,
    onSecondary: DSColors.moonWhite,
    secondaryContainer: DSColors.glowJade,
    onSecondaryContainer: DSColors.celadonDeep,
    error: DSColors.cinnabar,
    onError: DSColors.moonWhite,
    surface: DSColors.surfaceRaised,
    onSurface: DSColors.textPrimary,
    surfaceContainerHighest: DSColors.surfaceLightSunken,
    outline: DSColors.hairlineStrong,
    outlineVariant: DSColors.hairline,
    shadow: Colors.black,
  );

  final bodyTheme = base.textTheme.apply(
    bodyColor: DSColors.textPrimary,
    displayColor: DSColors.textPrimary,
    fontFamilyFallback: DSTypography.sansFallback,
  );

  return base.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: DSColors.background,
    canvasColor: DSColors.background,
    dividerColor: DSColors.hairlineStrong,
    textTheme: bodyTheme.copyWith(
      displayLarge: DSTypography.displayLight(
        fontSize: 32,
        color: DSColors.textPrimary,
        height: 1.2,
      ),
      displayMedium: DSTypography.displayLight(
        fontSize: 28,
        color: DSColors.textPrimary,
        height: 1.2,
      ),
      displaySmall: DSTypography.displayLight(
        fontSize: 24,
        color: DSColors.textPrimary,
        height: 1.3,
      ),
      headlineLarge: DSTypography.displayLight(
        fontSize: 24,
        color: DSColors.textPrimary,
        height: 1.3,
      ),
      headlineMedium: DSTypography.displayLight(
        fontSize: 20,
        color: DSColors.textPrimary,
        height: 1.4,
      ),
      headlineSmall: DSTypography.displayLight(
        fontSize: 18,
        color: DSColors.textPrimary,
        height: 1.4,
      ),
      titleLarge: DSTypography.body(
        fontSize: 18,
        weight: FontWeight.w400,
        color: DSColors.textPrimary,
        height: 1.4,
      ),
      titleMedium: DSTypography.body(
        fontSize: 16,
        weight: FontWeight.w500,
        color: DSColors.textPrimary,
      ),
      titleSmall: DSTypography.body(
        fontSize: 14,
        weight: FontWeight.w500,
        color: DSColors.textPrimary,
      ),
      bodyLarge: DSTypography.body(
        fontSize: 14,
        weight: FontWeight.w400,
        color: DSColors.textPrimary,
        height: 1.6,
      ),
      bodyMedium: DSTypography.body(
        fontSize: 14,
        weight: FontWeight.w400,
        color: DSColors.textSecondary,
        height: 1.6,
      ),
      bodySmall: DSTypography.body(
        fontSize: 12,
        weight: FontWeight.w400,
        color: DSColors.textMuted,
        height: 1.5,
      ),
      labelLarge: DSTypography.overline(
        color: DSColors.textSecondary,
        fontSize: 11,
      ),
      labelMedium: DSTypography.overline(color: DSColors.textMuted),
      labelSmall: DSTypography.overline(color: DSColors.textFaint, fontSize: 9),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: DSColors.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: DSTypography.displayLight(
        fontSize: 20,
        color: DSColors.textPrimary,
        height: 1.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: DSColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.lg),
        side: BorderSide(color: DSColors.hairlineStrong, width: .8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DSColors.celadon,
        foregroundColor: DSColors.moonWhite,
        disabledBackgroundColor: DSColors.textFaint,
        disabledForegroundColor: DSColors.surfaceRaised,
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
        side: BorderSide(color: DSColors.hairlineStrong, width: 1),
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
      fillColor: DSColors.surfaceLightSunken,
      hintStyle: TextStyle(color: DSColors.textFaint),
      labelStyle: TextStyle(color: DSColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: BorderSide(color: DSColors.hairlineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: BorderSide(color: DSColors.hairlineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: BorderSide(color: DSColors.celadon, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DSColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      indicatorColor: DSColors.glowCinnabar,
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
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: DSColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: DSColors.glassStrong,
      showDragHandle: true,
      dragHandleColor: DSColors.textMuted,
      shape: const RoundedRectangleBorder(
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
        side: BorderSide(color: DSColors.hairlineStrong, width: .8),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: DSColors.hairlineStrong,
      thickness: .8,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: DSColors.surfaceLightSunken,
      selectedColor: DSColors.glowCinnabar,
      side: BorderSide(color: DSColors.hairlineStrong, width: .8),
      labelStyle: TextStyle(color: DSColors.textPrimary, fontSize: 12),
      secondaryLabelStyle: TextStyle(
        color: DSColors.moonWhite,
        fontSize: 12,
        fontWeight: FontWeight.w600,
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
            : DSColors.surfaceLightSunken,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DSColors.celadon,
      linearTrackColor: DSColors.surfaceLightSunken,
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

/// 道谕浅色底：纯暖白，无渐变、无装饰——让卦面内容成为唯一主角。
class DSDaoyuBackground extends StatelessWidget {
  const DSDaoyuBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: DSColors.background, child: child);
}
