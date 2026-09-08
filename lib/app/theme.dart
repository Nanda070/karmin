import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual tokens from Figma (Karmin, dark-only).
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

  static TextStyle tab({
    required bool selected,
    double fontSize = 11,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: selected ? KarminColors.carmine : KarminColors.muted,
      height: 1.3,
    );
  }
}

abstract final class KarminTheme {
  static ThemeData dark() {
    final sans = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(
      bodyColor: KarminColors.text,
      displayColor: KarminColors.text,
    );

    final textTheme = sans.copyWith(
      displayLarge: KarminTypography.display(fontSize: 34),
      displayMedium: KarminTypography.display(fontSize: 28),
      displaySmall: KarminTypography.display(fontSize: 24),
      headlineLarge: KarminTypography.display(fontSize: 28),
      headlineMedium: KarminTypography.display(fontSize: 22),
      headlineSmall: KarminTypography.title(fontSize: 18),
      titleLarge: KarminTypography.title(fontSize: 18),
      titleMedium: KarminTypography.title(fontSize: 16),
      titleSmall: KarminTypography.title(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: KarminTypography.body(fontSize: 16),
      bodyMedium: KarminTypography.body(fontSize: 14),
      bodySmall: KarminTypography.body(
        fontSize: 13,
        color: KarminColors.muted,
      ),
      labelLarge: KarminTypography.body(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: KarminTypography.label(fontSize: 12),
      labelSmall: KarminTypography.label(fontSize: 11),
    );

    final colorScheme = ColorScheme.dark(
      primary: KarminColors.carmine,
      onPrimary: KarminColors.text,
      secondary: KarminColors.steel,
      onSecondary: KarminColors.text,
      surface: KarminColors.surface,
      onSurface: KarminColors.text,
      error: KarminColors.carmineBright,
      onError: KarminColors.text,
      outline: KarminColors.hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KarminColors.ink,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: KarminColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: KarminTypography.display(fontSize: 22),
      ),
      cardTheme: const CardThemeData(
        color: KarminColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: KarminRadii.lgBorder),
      ),
      dividerColor: KarminColors.hairline,
      dividerTheme: const DividerThemeData(
        color: KarminColors.hairline,
        thickness: 0.5,
        space: 0,
      ),
      iconTheme: const IconThemeData(
        color: KarminColors.text,
        size: 20,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: KarminColors.carmine.withValues(alpha: 0.08),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KarminColors.navy,
        hintStyle: KarminTypography.body(color: KarminColors.muted),
        border: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: const BorderSide(color: KarminColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: const BorderSide(color: KarminColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: const BorderSide(color: KarminColors.carmine),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KarminColors.carmine,
          foregroundColor: KarminColors.text,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(
            borderRadius: KarminRadii.mdBorder,
          ),
          textStyle: KarminTypography.body(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KarminColors.carmine,
          textStyle: KarminTypography.body(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: KarminColors.carmine,
          ),
        ),
      ),
    );
  }
}
