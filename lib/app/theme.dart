import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual tokens from Figma (Karmin dark — default / first-class).
abstract final class KarminColors {
  static const Color ink = Color(0xFF07080C);
  static const Color navy = Color(0xFF152036);
  static const Color surface = Color(0xFF10141C);
  static const Color hairline = Color(0xFF2A3A5C);
  static const Color steel = Color(0xFF4A6A8A);
  static const Color muted = Color(0xFF8B93A7);
  static const Color text = Color(0xFFE8EAED);
  static const Color carmine = Color(0xFF9B1B30);
  static const Color carmineBright = Color(0xFFDB4257);
}

/// Complementary light tokens (Stage 4). Cream paper, not generic Material white.
abstract final class KarminLightColors {
  static const Color paper = Color(0xFFF4EFE6);
  static const Color surface = Color(0xFFFFFCF8);
  static const Color field = Color(0xFFEDE6DA);
  static const Color ink = Color(0xFF141820);
  static const Color hairline = Color(0xFFD4CBBE);
  static const Color muted = Color(0xFF6B645A);
  static const Color steel = Color(0xFF4A6A8A);
  static const Color carmine = KarminColors.carmine;
  static const Color carmineBright = KarminColors.carmineBright;
}

/// Resolved palette for the active brightness. Widgets must read this, not
/// hardcoded [KarminColors], so Light restyles chrome as well as Material.
@immutable
class KarminPalette extends ThemeExtension<KarminPalette> {
  const KarminPalette({
    required this.page,
    required this.pageMid,
    required this.pageEnd,
    required this.surface,
    required this.surfaceHi,
    required this.surfaceLo,
    required this.field,
    required this.fieldHi,
    required this.hairline,
    required this.muted,
    required this.text,
    required this.steel,
    required this.carmine,
    required this.carmineBright,
    required this.onCarmine,
    required this.accentText,
    required this.shadow,
    required this.isDark,
  });

  final Color page;
  final Color pageMid;
  final Color pageEnd;
  final Color surface;
  final Color surfaceHi;
  final Color surfaceLo;
  final Color field;
  final Color fieldHi;
  final Color hairline;
  final Color muted;
  final Color text;
  final Color steel;
  final Color carmine;
  final Color carmineBright;
  final Color onCarmine;
  final Color accentText;
  final Color shadow;
  final bool isDark;

  static KarminPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<KarminPalette>();
    return ext ?? dark;
  }

  static const KarminPalette dark = KarminPalette(
    page: KarminColors.ink,
    pageMid: Color(0xFF0C1018),
    pageEnd: KarminColors.navy,
    surface: KarminColors.surface,
    surfaceHi: Color(0xFF141A26),
    surfaceLo: Color(0xFF0C1018),
    field: KarminColors.navy,
    fieldHi: Color(0xFF1A2438),
    hairline: KarminColors.hairline,
    muted: KarminColors.muted,
    text: KarminColors.text,
    steel: KarminColors.steel,
    carmine: KarminColors.carmine,
    carmineBright: KarminColors.carmineBright,
    onCarmine: KarminColors.text,
    accentText: KarminColors.carmineBright,
    shadow: Color(0x59000000),
    isDark: true,
  );

  static const KarminPalette light = KarminPalette(
    page: KarminLightColors.paper,
    pageMid: Color(0xFFEFE8DC),
    pageEnd: KarminLightColors.field,
    surface: KarminLightColors.surface,
    surfaceHi: Color(0xFFFFFFFF),
    surfaceLo: Color(0xFFF6F0E4),
    field: KarminLightColors.field,
    fieldHi: Color(0xFFE4D9C8),
    hairline: KarminLightColors.hairline,
    muted: KarminLightColors.muted,
    text: KarminLightColors.ink,
    steel: KarminLightColors.steel,
    carmine: KarminLightColors.carmine,
    carmineBright: KarminLightColors.carmineBright,
    onCarmine: Color(0xFFFFF8F4),
    accentText: KarminLightColors.carmine,
    shadow: Color(0x24141820),
    isDark: false,
  );

  @override
  KarminPalette copyWith({
    Color? page,
    Color? pageMid,
    Color? pageEnd,
    Color? surface,
    Color? surfaceHi,
    Color? surfaceLo,
    Color? field,
    Color? fieldHi,
    Color? hairline,
    Color? muted,
    Color? text,
    Color? steel,
    Color? carmine,
    Color? carmineBright,
    Color? onCarmine,
    Color? accentText,
    Color? shadow,
    bool? isDark,
  }) {
    return KarminPalette(
      page: page ?? this.page,
      pageMid: pageMid ?? this.pageMid,
      pageEnd: pageEnd ?? this.pageEnd,
      surface: surface ?? this.surface,
      surfaceHi: surfaceHi ?? this.surfaceHi,
      surfaceLo: surfaceLo ?? this.surfaceLo,
      field: field ?? this.field,
      fieldHi: fieldHi ?? this.fieldHi,
      hairline: hairline ?? this.hairline,
      muted: muted ?? this.muted,
      text: text ?? this.text,
      steel: steel ?? this.steel,
      carmine: carmine ?? this.carmine,
      carmineBright: carmineBright ?? this.carmineBright,
      onCarmine: onCarmine ?? this.onCarmine,
      accentText: accentText ?? this.accentText,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  KarminPalette lerp(ThemeExtension<KarminPalette>? other, double t) {
    if (other is! KarminPalette) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return KarminPalette(
      page: mix(page, other.page),
      pageMid: mix(pageMid, other.pageMid),
      pageEnd: mix(pageEnd, other.pageEnd),
      surface: mix(surface, other.surface),
      surfaceHi: mix(surfaceHi, other.surfaceHi),
      surfaceLo: mix(surfaceLo, other.surfaceLo),
      field: mix(field, other.field),
      fieldHi: mix(fieldHi, other.fieldHi),
      hairline: mix(hairline, other.hairline),
      muted: mix(muted, other.muted),
      text: mix(text, other.text),
      steel: mix(steel, other.steel),
      carmine: mix(carmine, other.carmine),
      carmineBright: mix(carmineBright, other.carmineBright),
      onCarmine: mix(onCarmine, other.onCarmine),
      accentText: mix(accentText, other.accentText),
      shadow: mix(shadow, other.shadow),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// 8pt spacing scale.
abstract final class KarminSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Default horizontal page inset (~20).
  static const double pageX = xl;

  /// Minimum tap target (WCAG 2.5.5 / EAA).
  static const double tap = 48;
}

abstract final class KarminRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 18;
  static const double full = 999;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillBorder =
      BorderRadius.all(Radius.circular(pill));
}

/// Display serif + clean UI sans via google_fonts.
abstract final class KarminTypography {
  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    Color color = KarminColors.text,
    double height = 1.2,
    double? letterSpacing,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle title({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    Color color = KarminColors.text,
    double height = 1.3,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = KarminColors.text,
    double height = 1.35,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle label({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
    Color color = KarminColors.muted,
    double height = 1.3,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

abstract final class KarminTheme {
  static ThemeData dark() => _build(KarminPalette.dark);

  static ThemeData light() => _build(KarminPalette.light);

  static ThemeData _build(KarminPalette palette) {
    final brightness = palette.isDark ? Brightness.dark : Brightness.light;
    final sans = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(
      bodyColor: palette.text,
      displayColor: palette.text,
    );

    final textTheme = sans.copyWith(
      displayLarge: KarminTypography.display(fontSize: 34, color: palette.text),
      displayMedium:
          KarminTypography.display(fontSize: 28, color: palette.text),
      displaySmall: KarminTypography.display(fontSize: 24, color: palette.text),
      headlineLarge:
          KarminTypography.display(fontSize: 28, color: palette.text),
      headlineMedium:
          KarminTypography.display(fontSize: 22, color: palette.text),
      headlineSmall: KarminTypography.title(fontSize: 18, color: palette.text),
      titleLarge: KarminTypography.title(fontSize: 18, color: palette.text),
      titleMedium: KarminTypography.title(fontSize: 16, color: palette.text),
      titleSmall: KarminTypography.title(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: palette.text,
      ),
      bodyLarge: KarminTypography.body(fontSize: 16, color: palette.text),
      bodyMedium: KarminTypography.body(fontSize: 14, color: palette.text),
      bodySmall: KarminTypography.body(fontSize: 13, color: palette.muted),
      labelLarge: KarminTypography.body(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: palette.text,
      ),
      labelMedium: KarminTypography.label(fontSize: 12, color: palette.muted),
      labelSmall: KarminTypography.label(fontSize: 11, color: palette.muted),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.carmine,
      onPrimary: palette.onCarmine,
      secondary: palette.steel,
      onSecondary: palette.onCarmine,
      surface: palette.surface,
      onSurface: palette.text,
      error: palette.carmineBright,
      onError: palette.onCarmine,
      outline: palette.hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.page,
      textTheme: textTheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: KarminTypography.display(
          fontSize: 22,
          color: palette.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: KarminRadii.lgBorder),
      ),
      dividerColor: palette.hairline,
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 0.5,
        space: 0,
      ),
      iconTheme: IconThemeData(
        color: palette.text,
        size: 20,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: palette.carmine.withValues(alpha: 0.08),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.field,
        hintStyle: KarminTypography.body(color: palette.muted),
        border: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: BorderSide(color: palette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: BorderSide(color: palette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: BorderSide(color: palette.carmine),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.carmine,
          foregroundColor: palette.onCarmine,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: KarminRadii.mdBorder,
          ),
          textStyle: KarminTypography.body(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: palette.onCarmine,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accentText,
          minimumSize: const Size(KarminSpacing.tap, KarminSpacing.tap),
          textStyle: KarminTypography.body(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: palette.accentText,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.field,
        contentTextStyle: KarminTypography.body(color: palette.text),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.carmineBright;
          }
          return palette.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.carmine.withValues(alpha: 0.45);
          }
          return palette.hairline;
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.carmineBright,
      ),
    );
  }
}
