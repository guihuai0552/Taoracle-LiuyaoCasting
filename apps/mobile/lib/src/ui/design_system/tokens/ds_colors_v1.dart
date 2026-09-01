import 'package:flutter/material.dart';

/// Quiet Intelligence · 静默智能 · v1.0 色彩令牌。
///
/// 低饱和、克制、专业的色板（玄武岩黑 / 深海军蓝 / 中性灰 / 蓝灰 accent /
/// 苔藓绿 / 暗红 / 沙丘 / 米白），替代 v0.8「宣纸仪器」色板。
/// 真源规范：design-system-v1.0.md §2 颜色系统、§10 暗色/亮色模式。
///
/// 模式约定：
/// - **浅色模式（当前默认）**：米白 `#E7E7E0` 底 × 玄武岩黑 `#1E1E1E` 字。
/// - **暗色模式（Nocturne）**：玄武岩黑 `#1E1E1E` 底 × 米白 `#E7E7E0` 字，
///   卡片为深海军蓝 `#131936`。
///
/// 对比度说明（WCAG AA ≥ 4.5:1，文档 §2.3）：
/// - 浅色辅助文字不直接使用 `#8B8B8B`（on #E7E7E0 仅 ≈2.6:1，不达标），
///   故 [textSecondary] 取 `#5A5A54`（≈5.5:1）；`#8B8B8B` 在暗色底上
///   对比 ≈5:1 达标，作为 [textMutedNight] 使用。
/// - hairline 透明度按文档 §5.1「0.5px 中性灰 opacity 0.3」取 30%。
///
/// 五行色（wood/fire/earth/metal/water）为卦面专业核心载体，**保留不动**
/// （v1.0 §2.2，值与 v0.8 完全一致）。
abstract final class DSColorsV1 {
  // —— 主色板（文档 §2.1）——
  /// 玄武岩黑：暗色模式主背景、浅色模式主要文字。
  static const Color primary = Color(0xFF1E1E1E);

  /// 深海军蓝：卡片背景、弹层背景、次级容器（暗色模式 surface）。
  static const Color primaryVariant = Color(0xFF131936);

  /// 蓝灰（Astronomicon Grey · Pantone 7544C）：辅助元素、边框基础色。
  /// v1.0 修订：夜间灰阶统一蓝调化——无彩灰在深底上显「灰闷」，
  /// 参考图 Pantone 拼贴的辅助灰实为带蓝调的 #6E7C89，故 secondary 直接取 accent 同值。
  static const Color secondary = Color(0xFF6E7C89);

  /// 蓝灰色：强调色——仅用于动爻标记、世应高亮、趋势提示（信号配给制）。
  static const Color accent = Color(0xFF6E7C89);

  /// 蓝灰深阶：按下态、选中文字高对比（浅色底上对比 ≈4.6:1）。
  static const Color accentDeep = Color(0xFF55616C);

  /// 蓝灰浅阶：装饰刻线、选中底纹、禁用强调。
  static const Color accentDim = Color(0xFFB3BEC7);

  /// 蓝灰描边：选中组件边框（accent @40%）。
  static const Color accentLine = Color(0x666E7C89);

  /// 墨染弱底：浅底上的极淡染容器（标签底、开关轨、行 hover，玄武岩黑 @4%）。
  static const Color washInk = Color(0x0A1E1E1E);

  /// 苔藓绿：成功状态、完成标记、已保存。
  static const Color success = Color(0xFF68735F);

  /// 暗红色：警告、错误（极少使用，不大面积铺色）。
  static const Color warning = Color(0xFF4E0000);

  /// 沙丘色：暖色点缀、导出封面氛围与强调。
  static const Color surface = Color(0xFFCBB8A0);

  /// 米白色：浅色模式背景、暗色模式主要文字、彩色底上反白。
  static const Color background = Color(0xFFE7E7E0);

  // —— 浅色模式表面（文档 §10.2）——
  /// 抬升卡片面：米白基础上的微亮层（代替「#1E1E1E + 低透明」半透明容器，
  /// 保证深字对比与材质安静）。
  static const Color surfaceLight = Color(0xFFF2F2EC);

  /// 沉入面：输入框底、开关轨、标签底（米白基础上的微暗层）。
  static const Color surfaceLightSunken = Color(0xFFDEDED6);

  /// 强浮层（弹层、底栏）：米白高不透明玻璃。
  static const Color glassLight = Color(0xF2EFEFE8);

  // —— 暗色模式表面（文档 §10.1）——
  /// 暗色页面背景 = 玄武岩黑（同 [primary]）。
  static const Color nightBackground = Color(0xFF1E1E1E);

  /// 暗色卡片面 = 深海军蓝（同 [primaryVariant]）。
  static const Color nightSurface = Color(0xFF131936);

  /// 暗色抬升面：深海军蓝微亮层（弹层、悬浮面板）。
  static const Color nightSurfaceRaised = Color(0xFF1A2140);

  /// 暗色浮层（弹层、底栏）。
  static const Color glassNight = Color(0xF216192E);

  // —— 文本 · 浅色模式 ——
  /// 主文本（玄武岩黑；on #E7E7E0 ≈ 13:1）。
  static const Color textPrimary = Color(0xFF1E1E1E);

  /// 次文本（≈5.5:1 ✓AA；不使用 #8B8B8B，见类注释）。
  static const Color textSecondary = Color(0xFF5A5A54);

  /// 弱文本（≈3.6:1，仅限非关键辅助信息/大字号）。
  static const Color textMuted = Color(0xFF75756E);

  /// 弱化文本（占位、禁用）。
  static const Color textFaint = Color(0xFF9C9C94);

  // —— 文本 · 暗色模式（蓝调化：银蓝灰阶，拒绝无彩灰）——
  /// 主文本（米白；on #1E1E1E ≈ 13:1）。
  static const Color textPrimaryNight = Color(0xFFE7E7E0);

  /// 次文本（银蓝灰；on #1E1E1E ≈ 7.5:1 ✓AA）。
  static const Color textSecondaryNight = Color(0xFFA9B4BF);

  /// 弱文本（蓝灰；on #1E1E1E ≈ 5.5:1 ✓AA）。
  static const Color textMutedNight = Color(0xFF8B98A5);

  /// 弱化文本（占位、禁用；暗蓝灰）。
  static const Color textFaintNight = Color(0xFF5E6B77);

  // —— 边框与线（文档 §5.1 / §6.4）——
  /// 发丝线：0.5px 中性灰 @30%（表格行分隔、卡片边框）。
  static const Color hairline = Color(0x4D8B8B8B);

  /// 强发丝线：分区线、输入框描边（浅色实色灰，安静细线）。
  static const Color hairlineStrong = Color(0xFFABABA3);

  /// 暗色模式强发丝线（蓝灰 @35%，与 accent 同色相）。
  static const Color hairlineNight = Color(0x596E7C89);

  /// 刻度网格线（卦面 Technical Grid，浅色）。
  static const Color gridLine = Color(0xFFD6D6CE);

  /// 暗色模式刻度网格线。
  static const Color gridLineNight = Color(0xFF252B4A);

  // —— 五行（保留，不动 · v1.0 §2.2）——
  /// 木 · 木青。
  static const Color wood = Color(0xFF3E7B4F);

  /// 火 · 火赤。
  static const Color fire = Color(0xFFBF4433);

  /// 土 · 土黄。
  static const Color earth = Color(0xFF8B6F47);

  /// 金 · 金缃。
  static const Color metal = Color(0xFF9C7E2E);

  /// 水 · 水黢。
  static const Color water = Color(0xFF2E6E96);

  // —— 辉光/淡染（wash 系：行底、标签底的淡染色）——
  /// 蓝灰淡染（动爻行底、选中面板高亮；accent @12%）。
  static const Color glowAccent = Color(0x1F6E7C89);

  /// 蓝灰强淡染（选中标签底；accent @20%）。
  static const Color glowAccentStrong = Color(0x336E7C89);

  /// 苔藓绿淡染（成功/完成标记底）。
  static const Color glowSuccess = Color(0x1F68735F);

  /// 暗红淡染（错误轻提示底）。
  static const Color glowWarning = Color(0x144E0000);

  /// 警示亮阶（Nocturne）：暗红 `#4E0000` 在深底上不可见，
  /// 暗色模式警示文字/标记取此亮红（值承 v0.8 Nocturne cinnabarSoft）。
  static const Color warningNight = Color(0xFFC86A5F);

  /// 警示淡染（Nocturne）：亮红 @15%，用于暗底警示提示卡底。
  static const Color glowWarningNight = Color(0x26C86A5F);

  /// 沙丘淡染（导出封面、归档标记暖点缀）。
  static const Color glowDune = Color(0x1FCBB8A0);
}
