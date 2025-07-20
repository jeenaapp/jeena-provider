import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF002B4E), // Royal Blue
        secondary: const Color(0xFFC9A14C), // Luxury Gold
        tertiary: const Color(0xFFEE8B60),
        surface: const Color(0xFFF1F4F8),
        error: const Color(0xFFFF5963),
        onPrimary: const Color(0xFFFFFFFF),
        onSecondary: const Color(0xFF15161E),
        onTertiary: const Color(0xFF15161E),
        onSurface: const Color(0xFF15161E),
        onError: const Color(0xFFFFFFFF),
        outline: const Color(0xFFB0BEC5),
      ),
      brightness: Brightness.light,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cairo(
          fontSize: 57.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF002B4E),
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 45.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF002B4E),
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: 36.0,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF002B4E),
        ),
        headlineLarge: GoogleFonts.cairo(
          fontSize: 32.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF002B4E),
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 24.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002B4E),
        ),
        headlineSmall: GoogleFonts.cairo(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF002B4E),
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002B4E),
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002B4E),
        ),
        titleSmall: GoogleFonts.cairo(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002B4E),
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002B4E),
        ),
        labelMedium: GoogleFonts.cairo(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002B4E),
        ),
        labelSmall: GoogleFonts.cairo(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002B4E),
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF15161E),
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF15161E),
        ),
        bodySmall: GoogleFonts.cairo(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF15161E),
        ),
      ),
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF4A90E2), // Lighter blue for dark mode
        secondary: const Color(0xFFC9A14C), // Luxury Gold
        tertiary: const Color(0xFFEE8B60),
        surface: const Color(0xFF15161E),
        error: const Color(0xFFFF5963),
        onPrimary: const Color(0xFFFFFFFF),
        onSecondary: const Color(0xFFE5E7EB),
        onTertiary: const Color(0xFFE5E7EB),
        onSurface: const Color(0xFFE5E7EB),
        onError: const Color(0xFFFFFFFF),
        outline: const Color(0xFF37474F),
      ),
      brightness: Brightness.dark,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cairo(
          fontSize: 57.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 45.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: 36.0,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE5E7EB),
        ),
        headlineLarge: GoogleFonts.cairo(
          fontSize: 32.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 24.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        headlineSmall: GoogleFonts.cairo(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE5E7EB),
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        titleSmall: GoogleFonts.cairo(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        labelMedium: GoogleFonts.cairo(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        labelSmall: GoogleFonts.cairo(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        bodySmall: GoogleFonts.cairo(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
      ),
    );