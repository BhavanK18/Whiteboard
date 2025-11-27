import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the high-contrast visual language for the redesigned experience.
///
/// We bias the palette towards a dimmed workspace inspired by modern
/// collaborative design tools. The dark theme is now the primary experience,
/// while a soft-light variant is retained for parity.
class AppTheme {
  AppTheme._();

  // Core colors used throughout the UI.
  static const Color _ink = Color(0xFF0B1220);
  static const Color _slate = Color(0xFF111827);
  static const Color _slateSurface = Color(0xFF1F2937);
  static const Color _mutedBorder = Color(0xFF374151);
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryVariant = Color(0xFF818CF8);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);

  static const Color _lightBackground = Color(0xFFF9FAFB);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE5E7EB);

  /// Typography helper applied to both themes so components pick up the same
  /// type scale regardless of brightness.
  static TextTheme _textTheme(TextTheme base) {
    final baseColor = base.bodyMedium?.color ?? Colors.white;
    final subduedColor = baseColor.withOpacity(baseColor.opacity * 0.72 + 0.08);

    return GoogleFonts.interTextTheme(base).copyWith(
      headlineLarge: GoogleFonts.inter(
        color: base.headlineLarge?.color ?? baseColor,
        fontWeight: FontWeight.w600,
        fontSize: 32,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.inter(
        color: base.titleLarge?.color ?? baseColor,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      bodyLarge: GoogleFonts.inter(
        color: base.bodyLarge?.color ?? baseColor,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.inter(
        color: base.bodyMedium?.color ?? baseColor,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      bodySmall: GoogleFonts.inter(
        color: base.bodySmall?.color ?? subduedColor,
        fontWeight: FontWeight.w400,
        fontSize: 13,
      ),
      labelLarge: GoogleFonts.inter(
        color: base.labelLarge?.color ?? baseColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: GoogleFonts.inter(
        color: base.labelMedium?.color ?? subduedColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  static ThemeData _baseDark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _primaryVariant,
      onSecondary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: _slateSurface,
      onSurface: Colors.white,
      background: _slate,
      onBackground: Colors.white,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _slate,
      canvasColor: _slateSurface,
      textTheme: _textTheme(base.textTheme),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _slateSurface,
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 24),
        unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.6)),
        indicatorColor: _primary.withOpacity(0.12),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _slateSurface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: _slateSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _mutedBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _slateSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 15),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _ink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _mutedBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _mutedBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.inter(color: Colors.white70),
        labelStyle: GoogleFonts.inter(color: Colors.white70),
        floatingLabelStyle: GoogleFonts.inter(color: Colors.white),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
      ),
      dividerTheme: DividerThemeData(color: _mutedBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _ink,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _primaryVariant,
        selectionColor: _primary.withOpacity(0.35),
        selectionHandleColor: _primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static ThemeData _baseLight() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _primaryVariant,
      onSecondary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: _lightSurface,
      onSurface: const Color(0xFF111827),
      background: _lightBackground,
      onBackground: const Color(0xFF111827),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      canvasColor: _lightSurface,
      textTheme: _textTheme(base.textTheme),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _lightSurface,
        foregroundColor: const Color(0xFF111827),
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: const Color(0xFF111827),
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _lightBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF111827),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.inter(color: const Color(0xFF4B5563)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF4B5563)),
        floatingLabelStyle: GoogleFonts.inter(color: const Color(0xFF111827)),
        prefixIconColor: const Color(0xFF6B7280),
        suffixIconColor: const Color(0xFF6B7280),
      ),
      dividerTheme: DividerThemeData(color: _lightBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF111827),
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _primary,
        selectionColor: _primary.withOpacity(0.25),
        selectionHandleColor: _primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _lightBorder),
          foregroundColor: const Color(0xFF111827),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF111827)),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static ThemeData get darkTheme => _baseDark();
  static ThemeData get lightTheme => _baseLight();
}