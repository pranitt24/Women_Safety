import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kAccent = Color(0xFF0B7A6A); // Teal accent
const Color kSos = Color(0xFFC8202F);    // SOS red
const Color kBgLight = Color(0xFFE9EEEC); // Cool grey-green background
const Color kBgDark = Color(0xFF141A19);  // Cool dark background
const Color kCardLight = Color(0xFFFFFFFF);
const Color kCardDark = Color(0xFF1E2625);
const Color kWarningOrange = Color(0xFFE67E22);
const Color kSafeGreen = Color(0xFF27AE60);

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAccent,
        brightness: Brightness.light,
        primary: kAccent,
        secondary: kAccent,
        error: kSos,
        surface: kCardLight,
      ),
      scaffoldBackgroundColor: kBgLight,
    );

    return base.copyWith(
      textTheme: GoogleFonts.instrumentSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        displaySmall: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        titleMedium: GoogleFonts.instrumentSans(
          textStyle: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          textStyle: base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          textStyle: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: kCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1A000000)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAccent,
        brightness: Brightness.dark,
        primary: const Color(0xFF1ABC9C),
        secondary: const Color(0xFF1ABC9C),
        error: kSos,
        surface: kCardDark,
      ),
      scaffoldBackgroundColor: kBgDark,
    );

    return base.copyWith(
      textTheme: GoogleFonts.instrumentSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        displaySmall: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        titleMedium: GoogleFonts.instrumentSans(
          textStyle: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          textStyle: base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          textStyle: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: kCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x2AFFFFFF)),
        ),
      ),
    );
  }
}
