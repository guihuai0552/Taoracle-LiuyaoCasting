import 'package:flutter/material.dart';

import 'ds_colors_v1.dart';

/// DSColors · 道谕门面 · **浅色朱红体系（当前生产默认）**。
///
/// 依照「道谕六爻」线框图（wireframe-preview-approved.html）重建：
/// 暖白 `#F3F2EF` 底 × 纯白卡片 × 朱红主强调 `#A9282D` × 棕金辅助 `#AE8648`。
///
/// **本层字段名与 v0.2–v1.0 完全兼容**，存量引用零改动即整体换肤：
/// - 底色系：暗色三层 → 浅色三层（background / surface / surfaceRaised）
/// - 信号系：蓝灰 accent 族 → 朱红 celadon 族（主按钮、选中态、动爻）
/// - 文本系：米白/蓝灰 night 系 → 浓墨灰阶（textPrimary #202020）
/// - 警示系：亮红 → 朱红警示（cinnabar #A9282D）
/// - 五行系：**保留原值不动**（卦面专业核心载体，红线字段）
///
/// 主题接线：buildLiuyaoTheme() → buildDaoyuTheme()。
/// 暗色（Nocturne）与 L2 高光场景仍可用 [DSColorsNocturne] 底层令牌。
abstract final class DSColors {
  // —— 底色 · 浅色三层 ——
  /// 页面背景（暖白 · 线框图 #F3F2EF）。
  static const Color background = Color(0xFFF3F2EF);

  /// 深一档底：L2 衬纸、沉入面（暖灰微亮层）。
  static const Color bgDeep = Color(0xFFEAE7E2);

  /// 次级表面（图标底、分组底、表头内衬）= 纯白。
  static const Color surface = Color(0xFFFFFFFF);

  /// 抬升表面（卡片、面板底）= 纯白。
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// 沉入表面（未选中控件底、次级分组底）。
  static const Color surfaceLightSunken = Color(0xFFEDEBE6);

  // —— 浮层层 ——
  /// 弹层、悬浮面板底（浅色高不透明玻璃）。
  static const Color glass = Color(0xF7FFFFFF);

  /// 强浮层（导航、底栏、关键浮层）。
  static const Color glassStrong = Color(0xFAFFFFFF);

  /// 弱底（输入框底、开关轨、标签底：浅色抬升面）。
  static const Color glassWeak = Color(0x59FFFFFF);

  // —— 信号配给（朱红 accent 族）——
  /// 朱红：主强调、动爻、当前用神、选中态（信号配给制：仅关键信息）。
  static const Color celadon = Color(0xFFA9282D);

  /// 暗红：选中文字、按下态、链接（浅色底高对比）。
  static const Color celadonDeep = Color(0xFF8F2027);

  /// 浅朱红：装饰刻线、选中底纹。
  static const Color celadonDim = Color(0xFFC96064);

  /// 棕金：仪式高亮、文书层选中态（线框图辅助强调）。
  static const Color amber = Color(0xFFAE8648);

  /// 棕金：世应文字、变出之爻、次要强调。
  static const Color jade = Color(0xFFAE8648);

  /// 冷蓝灰：辅助信息、星宿/天文。
  static const Color coldBlue = Color(0xFF6E7C89);

  /// 纯白：彩色底上的反白文字。
  static const Color moonWhite = Color(0xFFFFFFFF);

  // —— 信号配给制（显式命名）——
  /// 朱红信号：动爻标记。
  static const Color signalJade = Color(0xFFA9282D);

  /// 棕金信号：变出之爻。
  static const Color signalLake = Color(0xFFAE8648);

  /// 暗红警示：旬空、月破警示。
  static const Color signalPlum = Color(0xFFC86A5F);

  /// 卦面刻度网格线（浅色）。
  static const Color gridLine = Color(0xFFE3E0DA);

  // —— 文书谱系 ——
  /// 档案卡片底 = 纯白。
  static const Color paper = Color(0xFFFFFFFF);

  /// 纸缘：边缘阴影 → 浅色暖灰线。
  static const Color paperEdge = Color(0xFFECEAE7);

  /// 世应竖线、印章落款 → 朱红（线框图红色装饰线）。
  static const Color sealRed = Color(0xFFA9282D);

  // —— 语义 ——
  /// 朱红：危险、错误、警示标签（不大面积使用）。
  static const Color cinnabar = Color(0xFFA9282D);

  /// 柔和警示浅阶。
  static const Color cinnabarSoft = Color(0xFFC96064);

  // —— 文本（浅色灰阶 · WCAG AA 校准）——
  /// 主文本（浓墨；on #F3F2EF ≈ 13:1）。
  static const Color textPrimary = Color(0xFF202020);

  /// 次文本（≈7:1 ✓AA）。
  static const Color textSecondary = Color(0xFF5A5A54);

  /// 弱文本（≈4.6:1，仅限非关键辅助信息/大字号）。
  static const Color textMuted = Color(0xFF777777);

  /// 弱化文本（占位、禁用）。
  static const Color textFaint = Color(0xFF9C9C94);

  // —— 边框与线 ——
  /// 细发丝线（默认边框、表格行分隔：浅色 0.5px）。
  static const Color hairline = Color(0x59B0ACA6);

  /// 强发丝线（分区线、输入框描边、卡片边框）。
  static const Color hairlineStrong = Color(0xFFE0DDD7);

  /// 朱红描边（选中组件边框）。
  static const Color metalLine = Color(0x66A9282D);

  /// 朱红描边直通（动爻行/选中行边框，朱红 @40%）。
  static const Color accentLine = Color(0x66A9282D);

  /// 等宽元数据弱文本。
  static const Color monoCool = Color(0xFF777777);

  // —— 五行（保留，不动 · 卦面专业核心载体）——
  static const Color wood = DSColorsV1.wood;
  static const Color fire = DSColorsV1.fire;
  static const Color earth = DSColorsV1.earth;
  static const Color metal = DSColorsV1.metal;
  static const Color water = DSColorsV1.water;

  // —— 辉光/淡底（wash 系）——
  /// 棕金淡染（仪式、归档标记）。
  static const Color glowAmber = Color(0x2EAE8648);

  /// 朱红淡染（选中、面板高亮）。
  static const Color glowCeladon = Color(0x1FA9282D);

  /// 棕金淡染（变爻、次级信号）。
  static const Color glowJade = Color(0x1FAE8648);

  /// 朱红强淡染（动爻克制高亮）。
  static const Color glowCinnabar = Color(0x20A9282D);

  /// 暗红淡染（旬空、月破淡底）。
  static const Color glowPlum = Color(0x26C86A5F);

  /// 朱红淡染直通（警示提示卡底）。
  static const Color glowWarning = Color(0x14A9282D);
}

/// 夜观星历 · Nocturne · 深底令牌（供 L2 高光场景：导出封面、起卦仪式）。
///
/// 全局默认已切换为浅色朱红体系；此组令牌保留供导出封面等深底场景使用。
abstract final class DSColorsNocturne {
  // —— 底色 · 三层墨 ——
  static const Color background = Color(0xFF0C1016);
  static const Color bgDeep = Color(0xFF080B10);
  static const Color surface = Color(0xFF141A23);
  static const Color surfaceRaised = Color(0xFF1A222E);

  // —— 玻璃/浮层层 ——
  static const Color glass = Color(0xCC141A23);
  static const Color glassStrong = Color(0xF2141A23);
  static const Color glassWeak = Color(0x591A222E);

  // —— 仪器温信号 ——
  static const Color celadon = Color(0xFF7CE8C4);
  static const Color celadonDeep = Color(0xFF4FC79B);
  static const Color celadonDim = Color(0xFF3E6B5C);
  static const Color amber = Color(0xFFC9A96E);
  static const Color jade = Color(0xFF5FB9E8);
  static const Color coldBlue = Color(0xFF8FB8D8);
  static const Color moonWhite = Color(0xFFD9D3C3);

  // —— 信号配给制 ——
  static const Color signalJade = Color(0xFF7CE8C4);
  static const Color signalLake = Color(0xFF5FB9E8);
  static const Color signalPlum = Color(0xFFD87BA8);
  static const Color gridLine = Color(0xFF223042);

  // —— 文书温 ——
  static const Color paper = Color(0xFFE6D9B8);
  static const Color paperEdge = Color(0xFFCBB98E);
  static const Color sealRed = Color(0xFFB04038);

  // —— 语义 ——
  static const Color cinnabar = Color(0xFFB04038);
  static const Color cinnabarSoft = Color(0xFFC86A5F);

  // —— 文本 ——
  static const Color textPrimary = Color(0xFFD9D3C3);
  static const Color textSecondary = Color(0xFFA09C8C);
  static const Color textMuted = Color(0xFF8F8C7E);
  static const Color textFaint = Color(0xFF5C5A50);

  // —— 边框与线 ——
  static const Color hairline = Color(0x29223042);
  static const Color hairlineStrong = Color(0x4D8892A0);
  static const Color metalLine = Color(0x4D7CE8C4);
  static const Color monoCool = Color(0xFF8892A0);

  // —— 五行（v1.13.4 提高饱和与白底对比，五行一眼可辨）——
  static const Color wood = Color(0xFF2F7D4F);
  static const Color fire = Color(0xFFC03A2E);
  static const Color earth = Color(0xFF8A6A45);
  static const Color metal = Color(0xFF96741B);
  static const Color water = Color(0xFF2C6CB8);

  // —— 辉光 ——
  static const Color glowAmber = Color(0x2EC9A96E);
  static const Color glowCeladon = Color(0x247CE8C4);
  static const Color glowJade = Color(0x245FB9E8);
  static const Color glowCinnabar = Color(0x1FB04038);
  static const Color glowPlum = Color(0x24D87BA8);
}
