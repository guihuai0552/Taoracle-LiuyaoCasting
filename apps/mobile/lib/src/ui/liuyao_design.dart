import 'package:flutter/material.dart';

import 'design_system/app_theme_v1.dart';
import 'design_system/tokens/ds_colors.dart';
import 'design_system/tokens/ds_colors_v1.dart';

/// 语义别名层：历史令牌映射到「道谕六爻」浅色朱红体系。
///
/// 迁移策略：不改既有 `LiuyaoColors.xxx` 引用，只在此处换语义值，
/// 全部页面一次性切换。命名保持旧称以避免大面积机械改动。
/// 当前取值经 [DSColors] 门面指向浅色朱红 token
/// （暖白底 × 纯白卡片 × 朱红主强调 × 棕金辅助），与生产主题一致。
abstract final class LiuyaoColors {
  /// 页面背景 → 宣纸米白。
  static const paper = DSColors.background;

  /// 抬升表面（卡片底）。
  static const paperRaised = DSColors.surfaceRaised;

  /// 次级表面（图标底、分组底）。
  static const parchment = DSColors.surface;

  /// 主文本 / 主色 → 浓墨。
  static const ink = DSColors.textPrimary;
  static const inkMedium = DSColors.textSecondary;
  static const inkMuted = DSColors.textMuted;

  /// 弱化线 → 发丝线。
  static const inkFaint = DSColors.hairlineStrong;

  /// 朱砂（克制使用）。
  static const cinnabar = DSColors.cinnabar;

  /// 玉青。
  static const jade = DSColors.jade;

  static const wood = DSColors.wood;
  static const fire = DSColors.fire;
  static const earth = DSColors.earth;
  static const metal = DSColors.metal;
  static const water = DSColors.water;
}

/// 语义别名层（v1.0）：Quiet Intelligence 色板的旧称映射。
///
/// 供迁移期使用——旧 `LiuyaoColors.xxx` 引用可逐处切换到本层，
/// 字段与 [LiuyaoColors] 一一对应，避免大面积机械改动。
/// 注意：本层服务于**浅色模式**（米白底 × 深字），暗色场景请直接用
/// [DSColorsV1] 的 night 系令牌。
abstract final class LiuyaoColorsV1 {
  /// 页面背景 → 米白。
  static const paper = DSColorsV1.background;

  /// 抬升表面（卡片底）→ 米白微亮层。
  static const paperRaised = DSColorsV1.surfaceLight;

  /// 次级表面（图标底、分组底、输入框底）→ 米白微暗层。
  static const parchment = DSColorsV1.surfaceLightSunken;

  /// 主文本 → 玄武岩黑。
  static const ink = DSColorsV1.textPrimary;
  static const inkMedium = DSColorsV1.textSecondary;
  static const inkMuted = DSColorsV1.textMuted;

  /// 弱化线 → 强发丝线。
  static const inkFaint = DSColorsV1.hairlineStrong;

  /// 警示（克制使用）→ 暗红。
  static const cinnabar = DSColorsV1.warning;

  /// 强调（仅关键信息）→ 蓝灰。
  static const jade = DSColorsV1.accent;

  // 五行（保留，不动）。
  static const wood = DSColorsV1.wood;
  static const fire = DSColorsV1.fire;
  static const earth = DSColorsV1.earth;
  static const metal = DSColorsV1.metal;
  static const water = DSColorsV1.water;
}

abstract final class LiuyaoSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class LiuyaoRadii {
  static const small = 8.0;
  static const card = 16.0;
  static const large = 18.0;
  static const phone = 24.0;
}

ThemeData buildLiuyaoTheme() {
  // 全局切换为「道谕六爻」浅色朱红主题（依照线框图 wireframe-preview-approved.html 还原）。
  // 暖白 #F3F2EF 底 × 纯白卡片 × 朱红 #A9282D 主强调 × 棕金 #AE8648 辅助。
  // DSColors 门面已同步指向浅色朱红 token。
  return buildDaoyuTheme();
}

class LiuyaoPaperBackground extends StatelessWidget {
  const LiuyaoPaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DSDaoyuBackground(child: child);
}

class ChineseLatticePainter extends CustomPainter {
  const ChineseLatticePainter({this.opacity = .09});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LiuyaoColors.inkMedium.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75;
    const unit = 24.0;

    void corner(Offset origin, double sx, double sy) {
      final path = Path();
      for (var index = 0; index < 4; index++) {
        final inset = index * 6.0;
        final width = unit * (4 - index * .55);
        final height = unit * (4 - index * .55);
        path.addRect(
          Rect.fromPoints(
            Offset(origin.dx + sx * inset, origin.dy + sy * inset),
            Offset(
              origin.dx + sx * (inset + width),
              origin.dy + sy * (inset + height),
            ),
          ),
        );
      }
      path.moveTo(origin.dx, origin.dy + sy * unit * 2);
      path.relativeLineTo(sx * unit * 4, 0);
      path.moveTo(origin.dx + sx * unit * 2, origin.dy);
      path.relativeLineTo(0, sy * unit * 4);
      canvas.drawPath(path, paint);
    }

    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);

    final grain = Paint()
      ..color = LiuyaoColors.inkMedium.withValues(alpha: opacity * .32)
      ..strokeWidth = .7;
    for (var y = 18.0; y < size.height; y += 47) {
      final x = (y * 1.73) % size.width;
      canvas.drawCircle(Offset(x, y), .55, grain);
    }
  }

  @override
  bool shouldRepaint(covariant ChineseLatticePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class LiuyaoPaperCard extends StatelessWidget {
  const LiuyaoPaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = LiuyaoColors.paperRaised,
    this.radius = LiuyaoRadii.card,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border
          ? Border.all(color: LiuyaoColors.inkFaint, width: .8)
          : null,
    ),
    child: child,
  );
}

class LiuyaoSealMark extends StatelessWidget {
  const LiuyaoSealMark({
    super.key,
    required this.character,
    required this.label,
  });

  final String character;
  final String label;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _SealLatticePainter(),
    child: SizedBox(
      width: 64,
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            character,
            // 印章字：道谕宋为随包字体，iOS / Android 渲染一致。
            style: const TextStyle(
              color: LiuyaoColors.cinnabar,
              fontFamily: 'DaoyuSong',
              fontFamilyFallback: ['Songti SC', 'Noto Serif CJK SC'],
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: LiuyaoColors.inkMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SealLatticePainter extends CustomPainter {
  const _SealLatticePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LiuyaoColors.cinnabar
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(outer, paint);
    canvas.drawRect(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      paint..color = LiuyaoColors.cinnabar.withValues(alpha: .66),
    );
    final lattice = Path()
      ..moveTo(7, size.height / 2)
      ..lineTo(15, size.height / 2)
      ..moveTo(size.width - 15, size.height / 2)
      ..lineTo(size.width - 7, size.height / 2)
      ..moveTo(size.width / 2, 7)
      ..lineTo(size.width / 2, 15)
      ..moveTo(size.width / 2, size.height - 15)
      ..lineTo(size.width / 2, size.height - 7);
    canvas.drawPath(lattice, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
