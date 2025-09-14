import 'package:flutter/material.dart';

class AppTheme {
  // True dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF1976D2), // Blue accent
      onPrimary: Colors.white,
      secondary: Color(0xFF64B5F6),
      onSecondary: Colors.white,
      surface: Color(0xFF121212),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF232A34),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Blue Black theme
  static ThemeData blueBlackTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF0A1A3D), // Deep blue
      onPrimary: Colors.white,
      secondary: Color(0xFF1976D2),
      onSecondary: Colors.white,
      surface: Color(0xFF0A1A3D),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF0A1A3D),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF142A5E),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF142A5E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Blue Accent theme
  static ThemeData blueAccentTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF1976D2), // Bright blue
      onPrimary: Colors.white,
      secondary: Color(0xFF64B5F6),
      onSecondary: Colors.white,
      surface: Color(0xFF101C2C),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF101C2C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A237E),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF1A237E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Midnight theme (deep navy/gray, teal accent)
  static ThemeData midnightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF22304A), // Deep navy
      onPrimary: Colors.white,
      secondary: Color(0xFF00BFAE), // Teal accent
      onSecondary: Colors.white,
      surface: Color(0xFF181C24),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF181C24),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF232B3E),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF232B3E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Slate theme (slate gray, blue accent)
  static ThemeData slateTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF374151), // Slate gray
      onPrimary: Colors.white,
      secondary: Color(0xFF60A5FA), // Blue accent
      onSecondary: Colors.white,
      surface: Color(0xFF23272F),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF23272F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF374151),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF374151),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Deep Purple theme (dark purple, magenta accent)
  static ThemeData deepPurpleTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF4527A0), // Deep purple
      onPrimary: Colors.white,
      secondary: Color(0xFFE040FB), // Magenta accent
      onSecondary: Colors.white,
      surface: Color(0xFF2A223A),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF2A223A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF311B4F),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF311B4F),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Emerald theme (emerald green, teal accent)
  static ThemeData emeraldTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF2ecc71), // Emerald
      onPrimary: Colors.white,
      secondary: Color(0xFF1abc9c), // Teal
      onSecondary: Colors.white,
      surface: Color(0xFF16241C),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF16241C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B3A2B),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF1B3A2B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Sunset theme (orange, pink, purple)
  static ThemeData sunsetTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFFF7043), // Orange
      onPrimary: Colors.white,
      secondary: Color(0xFFEC407A), // Pink
      onSecondary: Colors.white,
      surface: Color(0xFF2D193C),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF2D193C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6A1B9A),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF6A1B9A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Ocean theme (cyan, blue, indigo)
  static ThemeData oceanTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF00BCD4), // Cyan
      onPrimary: Colors.white,
      secondary: Color(0xFF1976D2), // Blue
      onSecondary: Colors.white,
      surface: Color(0xFF102027),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF102027),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF283593),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF283593),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Ruby theme (red, orange, magenta)
  static ThemeData rubyTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFD32F2F), // Red
      onPrimary: Colors.white,
      secondary: Color(0xFFFFA000), // Orange
      onSecondary: Colors.white,
      surface: Color(0xFF2B1B1B),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF2B1B1B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF8E24AA),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF8E24AA),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // WhatsApp Dark Mode inspired theme (deep gray, green accent, white text)
  static ThemeData glassTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF25D366), // WhatsApp green
      onPrimary: Colors.white,
      secondary: Color(0xFF075E54), // WhatsApp dark green
      onSecondary: Colors.white,
      surface: Color(0xFF121B22), // WhatsApp dark background
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121B22),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F2C34),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF1F2C34),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Color(0xFF1F2C34)),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1F2C34),
    ),
  );

  // Pure Dark Mode theme (true black, blue accent, white text)
  static ThemeData pureDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF1976D2), // Blue accent
      onPrimary: Colors.white,
      secondary: Color(0xFF64B5F6),
      onSecondary: Colors.white,
      surface: Color(0xFF000000), // True black
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181818),
      elevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF181818),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Color(0xFF181818)),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF181818),
    ),
  );
}
