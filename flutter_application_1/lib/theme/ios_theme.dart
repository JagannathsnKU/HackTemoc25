import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 🍎 iOS-Inspired Minimal Theme
/// Authentic Apple aesthetics with smooth, refined design
class IOSTheme {
  // 🎨 iOS Color System
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosIndigo = Color(0xFF5856D6);
  static const Color iosTeal = Color(0xFF5AC8FA);
  static const Color iosYellow = Color(0xFFFFCC00);
  static const Color iosOrange = Color(0xFFFF9500);
  static const Color iosPink = Color(0xFFFF2D55);
  static const Color iosPurple = Color(0xFFAF52DE);
  static const Color iosRed = Color(0xFFFF3B30);

  // iOS System Grays (Light Mode)
  static const Color iosGray = Color(0xFF8E8E93);
  static const Color iosGray2 = Color(0xFFAEAEB2);
  static const Color iosGray3 = Color(0xFFC7C7CC);
  static const Color iosGray4 = Color(0xFFD1D1D6);
  static const Color iosGray5 = Color(0xFFE5E5EA);
  static const Color iosGray6 = Color(0xFFF2F2F7);

  // iOS Backgrounds
  static const Color iosSystemBackground = Color(0xFFFFFFFF);
  static const Color iosSecondarySystemBackground = Color(0xFFF2F2F7);
  static const Color iosTertiarySystemBackground = Color(0xFFFFFFFF);
  
  // iOS Dark Mode
  static const Color iosDarkBackground = Color(0xFF000000);
  static const Color iosDarkSecondary = Color(0xFF1C1C1E);
  static const Color iosDarkTertiary = Color(0xFF2C2C2E);
  static const Color iosDarkQuaternary = Color(0xFF3A3A3C);

  // iOS Label Colors
  static const Color iosLabel = Color(0xFF000000);
  static const Color iosSecondaryLabel = Color(0x993C3C43);
  static const Color iosTertiaryLabel = Color(0x4D3C3C43);

  // iOS Blur Effects
  static const Color iosBlurLight = Color(0xF2FFFFFF);
  static const Color iosBlurMedium = Color(0xE6FFFFFF);

  /// 📱 San Francisco Font Weights (iOS System Font)
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// ✨ iOS Animations
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration standardDuration = Duration(milliseconds: 350);
  static const Duration slowDuration = Duration(milliseconds: 500);
  
  static const Curve iosCurve = Curves.easeInOut;
  static const Curve iosBounceCurve = Curves.easeOut;
  static const Curve iosSpringCurve = Curves.easeInOutCubic;

  /// 🎨 iOS Frosted Glass Card
  static BoxDecoration frostedGlass({
    Color? color,
    double blur = 20,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: (color ?? iosBlurLight).withOpacity(0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 💎 iOS Elevated Card
  static BoxDecoration iosCard({
    Color? color,
    double borderRadius = 16,
    bool pressed = false,
  }) {
    return BoxDecoration(
      color: color ?? iosSystemBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: pressed
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  /// 🎯 iOS Button Style
  static BoxDecoration iosButton({
    required Color color,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// 📱 Light Theme (iOS Style)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: iosSecondarySystemBackground,
      primaryColor: iosBlue,
      
      colorScheme: const ColorScheme.light(
        primary: iosBlue,
        secondary: iosGreen,
        surface: iosSystemBackground,
        error: iosRed,
      ),

      // iOS Typography (San Francisco style)
      textTheme: const TextTheme(
        // Large Title (iOS)
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: bold,
          color: iosLabel,
          letterSpacing: 0.374,
          height: 1.2,
        ),
        // Title 1
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: regular,
          color: iosLabel,
          letterSpacing: 0.364,
          height: 1.3,
        ),
        // Title 2
        displaySmall: TextStyle(
          fontSize: 22,
          fontWeight: regular,
          color: iosLabel,
          letterSpacing: 0.352,
          height: 1.3,
        ),
        // Title 3
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: semibold,
          color: iosLabel,
          letterSpacing: 0.38,
          height: 1.3,
        ),
        // Headline
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: semibold,
          color: iosLabel,
          letterSpacing: -0.408,
          height: 1.3,
        ),
        // Body
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: regular,
          color: iosLabel,
          letterSpacing: -0.408,
          height: 1.4,
        ),
        // Callout
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: regular,
          color: iosLabel,
          letterSpacing: -0.32,
          height: 1.4,
        ),
        // Subheadline
        bodySmall: TextStyle(
          fontSize: 15,
          fontWeight: regular,
          color: iosSecondaryLabel,
          letterSpacing: -0.24,
          height: 1.4,
        ),
        // Footnote
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: regular,
          color: iosSecondaryLabel,
          letterSpacing: -0.078,
          height: 1.35,
        ),
        // Caption
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: regular,
          color: iosSecondaryLabel,
          letterSpacing: 0,
          height: 1.35,
        ),
      ),

      // iOS AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: iosSecondarySystemBackground,
        foregroundColor: iosLabel,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: semibold,
          color: iosLabel,
          letterSpacing: -0.408,
        ),
      ),

      // iOS Card
      cardTheme: CardThemeData(
        color: iosSystemBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // iOS Divider
      dividerTheme: const DividerThemeData(
        color: iosGray5,
        thickness: 0.5,
        space: 0.5,
      ),

      // iOS Icon Theme
      iconTheme: const IconThemeData(
        color: iosBlue,
        size: 22,
      ),
    );
  }

  /// 🌙 Dark Theme (iOS Style)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: iosDarkBackground,
      primaryColor: iosBlue,
      
      colorScheme: const ColorScheme.dark(
        primary: iosBlue,
        secondary: iosGreen,
        surface: iosDarkSecondary,
        error: iosRed,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: bold,
          color: Colors.white,
          letterSpacing: 0.374,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: regular,
          color: Colors.white,
          letterSpacing: -0.408,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: iosDarkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: iosDarkSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// 🎨 iOS System Colors (Dynamic)
  static List<Color> get systemColors => [
    iosBlue,
    iosGreen,
    iosIndigo,
    iosTeal,
    iosYellow,
    iosOrange,
    iosPink,
    iosPurple,
    iosRed,
  ];

  /// ✨ SF Symbols Style Icons (sizes)
  static const double iconSmall = 16;
  static const double iconRegular = 22;
  static const double iconMedium = 28;
  static const double iconLarge = 34;

  /// 📏 iOS Spacing System
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  /// 🔲 iOS Corner Radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 20;
}
