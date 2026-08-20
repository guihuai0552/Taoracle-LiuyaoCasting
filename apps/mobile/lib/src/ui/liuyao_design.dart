import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class LiuyaoColors {
  static const paper = Color(0xFFF5F0E6);
  static const paperRaised = Color(0xFFF8F4E8);
  static const parchment = Color(0xFFF2E8D5);
  static const ink = Color(0xFF1C1C1C);
  static const inkMedium = Color(0xFF3A3A3A);
  static const inkMuted = Color(0xFF5C5C5C);
  static const inkFaint = Color(0xFFD0D0D0);
  static const cinnabar = Color(0xFFB22222);
  static const jade = Color(0xFF3F6250);

  static const wood = Color(0xFF347445);
  static const fire = Color(0xFFC23A32);
  static const earth = Color(0xFF8B7668);
  static const metal = Color(0xFFD49A26);
  static const water = Color(0xFF216B9B);
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
  static const card = 12.0;
  static const large = 18.0;
  static const phone = 24.0;
}

ThemeData buildLiuyaoTheme() {
  const colors = ColorScheme.light(
    primary: LiuyaoColors.cinnabar,
    onPrimary: LiuyaoColors.paperRaised,
    secondary: LiuyaoColors.ink,
    onSecondary: LiuyaoColors.paperRaised,
    surface: LiuyaoColors.paperRaised,
    onSurface: LiuyaoColors.ink,
    error: LiuyaoColors.cinnabar,
    onError: LiuyaoColors.paperRaised,
    outline: LiuyaoColors.inkFaint,
    outlineVariant: Color(0x663A3A3A),
  );
  final base = ThemeData.light(useMaterial3: true);
  final bodyTheme = base.textTheme.apply(
    bodyColor: LiuyaoColors.inkMedium,
    displayColor: LiuyaoColors.ink,
    fontFamilyFallback: const [
      'PingFang SC',
      'Noto Sans CJK SC',
      'Noto Sans SC',
    ],
  );
  TextStyle serif(TextStyle? source) => (source ?? const TextStyle()).copyWith(
    color: LiuyaoColors.ink,
    fontFamily: 'Songti SC',
    fontFamilyFallback: const ['Noto Serif CJK SC', 'Noto Serif SC', 'STSong'],
  );

  return base.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: LiuyaoColors.paper,
    canvasColor: LiuyaoColors.paper,
    dividerColor: LiuyaoColors.inkFaint,
    textTheme: bodyTheme.copyWith(
      displayLarge: serif(bodyTheme.displayLarge),
      displayMedium: serif(bodyTheme.displayMedium),
      displaySmall: serif(bodyTheme.displaySmall),
      headlineLarge: serif(bodyTheme.headlineLarge),
      headlineMedium: serif(bodyTheme.headlineMedium),
      headlineSmall: serif(bodyTheme.headlineSmall),
      titleLarge: serif(bodyTheme.titleLarge),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: LiuyaoColors.ink,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: LiuyaoColors.ink,
        fontFamily: 'Songti SC',
        fontFamilyFallback: ['Noto Serif CJK SC', 'Noto Serif SC', 'STSong'],
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: LiuyaoColors.paperRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        side: const BorderSide(color: LiuyaoColors.inkFaint, width: .8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LiuyaoColors.cinnabar,
        foregroundColor: LiuyaoColors.paperRaised,
        disabledBackgroundColor: LiuyaoColors.inkFaint,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LiuyaoRadii.small),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LiuyaoColors.ink,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: LiuyaoColors.ink, width: 1.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LiuyaoRadii.small),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LiuyaoColors.paperRaised,
      hintStyle: const TextStyle(color: LiuyaoColors.inkMuted),
      labelStyle: const TextStyle(color: LiuyaoColors.inkMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        borderSide: const BorderSide(color: LiuyaoColors.inkFaint),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        borderSide: const BorderSide(color: LiuyaoColors.inkFaint),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        borderSide: const BorderSide(color: LiuyaoColors.cinnabar, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LiuyaoColors.paperRaised.withValues(alpha: .96),
      surfaceTintColor: Colors.transparent,
      indicatorColor: LiuyaoColors.cinnabar.withValues(alpha: .10),
      elevation: 0,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? LiuyaoColors.cinnabar
              : LiuyaoColors.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? LiuyaoColors.cinnabar
              : LiuyaoColors.inkMuted,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
  );
}

class LiuyaoPaperBackground extends StatelessWidget {
  const LiuyaoPaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: LiuyaoColors.paper,
    child: CustomPaint(painter: const ChineseLatticePainter(), child: child),
  );
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
            style: const TextStyle(
              color: LiuyaoColors.cinnabar,
              fontFamily: 'Songti SC',
              fontFamilyFallback: ['Noto Serif CJK SC', 'STSong'],
              fontSize: 24,
              fontWeight: FontWeight.w900,
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
