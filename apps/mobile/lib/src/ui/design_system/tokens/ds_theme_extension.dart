import 'package:flutter/material.dart';

import 'ds_colors.dart';

class DSColorsScheme extends ThemeExtension<DSColorsScheme> {
  const DSColorsScheme({
    required this.background,
    required this.bgDeep,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceLightSunken,
    required this.glass,
    required this.glassStrong,
    required this.glassWeak,
    required this.celadon,
    required this.celadonDeep,
    required this.celadonDim,
    required this.amber,
    required this.jade,
    required this.coldBlue,
    required this.moonWhite,
    required this.signalJade,
    required this.signalLake,
    required this.signalPlum,
    required this.gridLine,
    required this.paper,
    required this.paperEdge,
    required this.sealRed,
    required this.cinnabar,
    required this.cinnabarSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.hairline,
    required this.hairlineStrong,
    required this.metalLine,
    required this.accentLine,
    required this.monoCool,
    required this.wood,
    required this.fire,
    required this.earth,
    required this.metal,
    required this.water,
    required this.glowAmber,
    required this.glowCeladon,
    required this.glowJade,
    required this.glowCinnabar,
    required this.glowPlum,
    required this.glowWarning,
  });

  final Color background;
  final Color bgDeep;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceLightSunken;
  final Color glass;
  final Color glassStrong;
  final Color glassWeak;
  final Color celadon;
  final Color celadonDeep;
  final Color celadonDim;
  final Color amber;
  final Color jade;
  final Color coldBlue;
  final Color moonWhite;
  final Color signalJade;
  final Color signalLake;
  final Color signalPlum;
  final Color gridLine;
  final Color paper;
  final Color paperEdge;
  final Color sealRed;
  final Color cinnabar;
  final Color cinnabarSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color hairline;
  final Color hairlineStrong;
  final Color metalLine;
  final Color accentLine;
  final Color monoCool;
  final Color wood;
  final Color fire;
  final Color earth;
  final Color metal;
  final Color water;
  final Color glowAmber;
  final Color glowCeladon;
  final Color glowJade;
  final Color glowCinnabar;
  final Color glowPlum;
  final Color glowWarning;

  static const DSColorsScheme light = DSColorsScheme(
    background: DSColors.background,
    bgDeep: DSColors.bgDeep,
    surface: DSColors.surface,
    surfaceRaised: DSColors.surfaceRaised,
    surfaceLightSunken: DSColors.surfaceLightSunken,
    glass: DSColors.glass,
    glassStrong: DSColors.glassStrong,
    glassWeak: DSColors.glassWeak,
    celadon: DSColors.celadon,
    celadonDeep: DSColors.celadonDeep,
    celadonDim: DSColors.celadonDim,
    amber: DSColors.amber,
    jade: DSColors.jade,
    coldBlue: DSColors.coldBlue,
    moonWhite: DSColors.moonWhite,
    signalJade: DSColors.signalJade,
    signalLake: DSColors.signalLake,
    signalPlum: DSColors.signalPlum,
    gridLine: DSColors.gridLine,
    paper: DSColors.paper,
    paperEdge: DSColors.paperEdge,
    sealRed: DSColors.sealRed,
    cinnabar: DSColors.cinnabar,
    cinnabarSoft: DSColors.cinnabarSoft,
    textPrimary: DSColors.textPrimary,
    textSecondary: DSColors.textSecondary,
    textMuted: DSColors.textMuted,
    textFaint: DSColors.textFaint,
    hairline: DSColors.hairline,
    hairlineStrong: DSColors.hairlineStrong,
    metalLine: DSColors.metalLine,
    accentLine: DSColors.accentLine,
    monoCool: DSColors.monoCool,
    wood: DSColors.wood,
    fire: DSColors.fire,
    earth: DSColors.earth,
    metal: DSColors.metal,
    water: DSColors.water,
    glowAmber: DSColors.glowAmber,
    glowCeladon: DSColors.glowCeladon,
    glowJade: DSColors.glowJade,
    glowCinnabar: DSColors.glowCinnabar,
    glowPlum: DSColors.glowPlum,
    glowWarning: DSColors.glowWarning,
  );

  static const DSColorsScheme dark = DSColorsScheme(
    background: _DaoyuDarkTokens.background,
    bgDeep: _DaoyuDarkTokens.bgDeep,
    surface: _DaoyuDarkTokens.surface,
    surfaceRaised: _DaoyuDarkTokens.surfaceRaised,
    surfaceLightSunken: _DaoyuDarkTokens.surfaceLightSunken,
    glass: _DaoyuDarkTokens.glass,
    glassStrong: _DaoyuDarkTokens.glassStrong,
    glassWeak: _DaoyuDarkTokens.glassWeak,
    celadon: _DaoyuDarkTokens.celadon,
    celadonDeep: _DaoyuDarkTokens.celadonDeep,
    celadonDim: _DaoyuDarkTokens.celadonDim,
    amber: _DaoyuDarkTokens.amber,
    jade: _DaoyuDarkTokens.jade,
    coldBlue: _DaoyuDarkTokens.coldBlue,
    moonWhite: _DaoyuDarkTokens.moonWhite,
    signalJade: _DaoyuDarkTokens.signalJade,
    signalLake: _DaoyuDarkTokens.signalLake,
    signalPlum: _DaoyuDarkTokens.signalPlum,
    gridLine: _DaoyuDarkTokens.gridLine,
    paper: _DaoyuDarkTokens.paper,
    paperEdge: _DaoyuDarkTokens.paperEdge,
    sealRed: _DaoyuDarkTokens.sealRed,
    cinnabar: _DaoyuDarkTokens.cinnabar,
    cinnabarSoft: _DaoyuDarkTokens.cinnabarSoft,
    textPrimary: _DaoyuDarkTokens.textPrimary,
    textSecondary: _DaoyuDarkTokens.textSecondary,
    textMuted: _DaoyuDarkTokens.textMuted,
    textFaint: _DaoyuDarkTokens.textFaint,
    hairline: _DaoyuDarkTokens.hairline,
    hairlineStrong: _DaoyuDarkTokens.hairlineStrong,
    metalLine: _DaoyuDarkTokens.metalLine,
    accentLine: _DaoyuDarkTokens.accentLine,
    monoCool: _DaoyuDarkTokens.monoCool,
    wood: DSColors.wood,
    fire: DSColors.fire,
    earth: DSColors.earth,
    metal: DSColors.metal,
    water: DSColors.water,
    glowAmber: _DaoyuDarkTokens.glowAmber,
    glowCeladon: _DaoyuDarkTokens.glowCeladon,
    glowJade: _DaoyuDarkTokens.glowJade,
    glowCinnabar: _DaoyuDarkTokens.glowCinnabar,
    glowPlum: _DaoyuDarkTokens.glowPlum,
    glowWarning: _DaoyuDarkTokens.glowWarning,
  );

  @override
  DSColorsScheme copyWith({
    Color? background,
    Color? bgDeep,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceLightSunken,
    Color? glass,
    Color? glassStrong,
    Color? glassWeak,
    Color? celadon,
    Color? celadonDeep,
    Color? celadonDim,
    Color? amber,
    Color? jade,
    Color? coldBlue,
    Color? moonWhite,
    Color? signalJade,
    Color? signalLake,
    Color? signalPlum,
    Color? gridLine,
    Color? paper,
    Color? paperEdge,
    Color? sealRed,
    Color? cinnabar,
    Color? cinnabarSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? hairline,
    Color? hairlineStrong,
    Color? metalLine,
    Color? accentLine,
    Color? monoCool,
    Color? wood,
    Color? fire,
    Color? earth,
    Color? metal,
    Color? water,
    Color? glowAmber,
    Color? glowCeladon,
    Color? glowJade,
    Color? glowCinnabar,
    Color? glowPlum,
    Color? glowWarning,
  }) => DSColorsScheme(
    background: background ?? this.background,
    bgDeep: bgDeep ?? this.bgDeep,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceLightSunken: surfaceLightSunken ?? this.surfaceLightSunken,
    glass: glass ?? this.glass,
    glassStrong: glassStrong ?? this.glassStrong,
    glassWeak: glassWeak ?? this.glassWeak,
    celadon: celadon ?? this.celadon,
    celadonDeep: celadonDeep ?? this.celadonDeep,
    celadonDim: celadonDim ?? this.celadonDim,
    amber: amber ?? this.amber,
    jade: jade ?? this.jade,
    coldBlue: coldBlue ?? this.coldBlue,
    moonWhite: moonWhite ?? this.moonWhite,
    signalJade: signalJade ?? this.signalJade,
    signalLake: signalLake ?? this.signalLake,
    signalPlum: signalPlum ?? this.signalPlum,
    gridLine: gridLine ?? this.gridLine,
    paper: paper ?? this.paper,
    paperEdge: paperEdge ?? this.paperEdge,
    sealRed: sealRed ?? this.sealRed,
    cinnabar: cinnabar ?? this.cinnabar,
    cinnabarSoft: cinnabarSoft ?? this.cinnabarSoft,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    textFaint: textFaint ?? this.textFaint,
    hairline: hairline ?? this.hairline,
    hairlineStrong: hairlineStrong ?? this.hairlineStrong,
    metalLine: metalLine ?? this.metalLine,
    accentLine: accentLine ?? this.accentLine,
    monoCool: monoCool ?? this.monoCool,
    wood: wood ?? this.wood,
    fire: fire ?? this.fire,
    earth: earth ?? this.earth,
    metal: metal ?? this.metal,
    water: water ?? this.water,
    glowAmber: glowAmber ?? this.glowAmber,
    glowCeladon: glowCeladon ?? this.glowCeladon,
    glowJade: glowJade ?? this.glowJade,
    glowCinnabar: glowCinnabar ?? this.glowCinnabar,
    glowPlum: glowPlum ?? this.glowPlum,
    glowWarning: glowWarning ?? this.glowWarning,
  );

  @override
  DSColorsScheme lerp(ThemeExtension<DSColorsScheme>? other, double t) {
    if (other is! DSColorsScheme) return this;
    return DSColorsScheme(
      background: Color.lerp(background, other.background, t)!,
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceLightSunken: Color.lerp(
        surfaceLightSunken,
        other.surfaceLightSunken,
        t,
      )!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      glassWeak: Color.lerp(glassWeak, other.glassWeak, t)!,
      celadon: Color.lerp(celadon, other.celadon, t)!,
      celadonDeep: Color.lerp(celadonDeep, other.celadonDeep, t)!,
      celadonDim: Color.lerp(celadonDim, other.celadonDim, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      jade: Color.lerp(jade, other.jade, t)!,
      coldBlue: Color.lerp(coldBlue, other.coldBlue, t)!,
      moonWhite: Color.lerp(moonWhite, other.moonWhite, t)!,
      signalJade: Color.lerp(signalJade, other.signalJade, t)!,
      signalLake: Color.lerp(signalLake, other.signalLake, t)!,
      signalPlum: Color.lerp(signalPlum, other.signalPlum, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paperEdge: Color.lerp(paperEdge, other.paperEdge, t)!,
      sealRed: Color.lerp(sealRed, other.sealRed, t)!,
      cinnabar: Color.lerp(cinnabar, other.cinnabar, t)!,
      cinnabarSoft: Color.lerp(cinnabarSoft, other.cinnabarSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      metalLine: Color.lerp(metalLine, other.metalLine, t)!,
      accentLine: Color.lerp(accentLine, other.accentLine, t)!,
      monoCool: Color.lerp(monoCool, other.monoCool, t)!,
      wood: Color.lerp(wood, other.wood, t)!,
      fire: Color.lerp(fire, other.fire, t)!,
      earth: Color.lerp(earth, other.earth, t)!,
      metal: Color.lerp(metal, other.metal, t)!,
      water: Color.lerp(water, other.water, t)!,
      glowAmber: Color.lerp(glowAmber, other.glowAmber, t)!,
      glowCeladon: Color.lerp(glowCeladon, other.glowCeladon, t)!,
      glowJade: Color.lerp(glowJade, other.glowJade, t)!,
      glowCinnabar: Color.lerp(glowCinnabar, other.glowCinnabar, t)!,
      glowPlum: Color.lerp(glowPlum, other.glowPlum, t)!,
      glowWarning: Color.lerp(glowWarning, other.glowWarning, t)!,
    );
  }
}

abstract final class _DaoyuDarkTokens {
  static const Color background = Color(0xFF14110D);
  static const Color bgDeep = Color(0xFF0E0B08);
  static const Color surface = Color(0xFF1F1B17);
  static const Color surfaceRaised = Color(0xFF25201B);
  static const Color surfaceLightSunken = Color(0xFF1A1612);
  static const Color glass = Color(0xCC1A1612);
  static const Color glassStrong = Color(0xE61A1612);
  static const Color glassWeak = Color(0x33201C18);

  static const Color celadon = Color(0xFFD4584E);
  static const Color celadonDeep = Color(0xFFE66860);
  static const Color celadonDim = Color(0xFFB04038);
  static const Color amber = Color(0xFFD9B26E);
  static const Color jade = Color(0xFFD9B26E);
  static const Color coldBlue = Color(0xFF98AAB8);
  static const Color moonWhite = Color(0xFFE8E2D8);

  static const Color signalJade = Color(0xFFD4584E);
  static const Color signalLake = Color(0xFFD9B26E);
  static const Color signalPlum = Color(0xFFE6866A);

  static const Color gridLine = Color(0xFF2D2823);
  static const Color paper = Color(0xFF25201B);
  static const Color paperEdge = Color(0xFF1A1612);
  static const Color sealRed = Color(0xFFD4584E);

  static const Color cinnabar = Color(0xFFD4584E);
  static const Color cinnabarSoft = Color(0xFFE6866A);

  static const Color textPrimary = Color(0xFFE8E2D8);
  static const Color textSecondary = Color(0xFFB5AFA3);
  static const Color textMuted = Color(0xFF8A857A);
  static const Color textFaint = Color(0xFF5C5750);

  static const Color hairline = Color(0x3DD9B26E);
  static const Color hairlineStrong = Color(0xFF3A3530);
  static const Color metalLine = Color(0x66D4584E);
  static const Color accentLine = Color(0x66D4584E);
  static const Color monoCool = Color(0xFF8A857A);

  static const Color glowAmber = Color(0x2ED9B26E);
  static const Color glowCeladon = Color(0x1FD4584E);
  static const Color glowJade = Color(0x1FD9B26E);
  static const Color glowCinnabar = Color(0x20D4584E);
  static const Color glowPlum = Color(0x26E6866A);
  static const Color glowWarning = Color(0x14D4584E);
}

extension DSColorsContext on BuildContext {
  DSColorsScheme get ds =>
      Theme.of(this).extension<DSColorsScheme>() ?? DSColorsScheme.light;
}
