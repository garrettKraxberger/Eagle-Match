import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class USGATheme {
  // USGA Color Palette - Enhanced for modern UI
  static const Color primaryNavy = Color(0xFF1B365D);
  static const Color secondaryNavy = Color(0xFF2C4F70);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentRed = Color(0xFFCC2936);
  static const Color lightRed = Color(0xFFE8384F);
  
  // Modern neutral palette
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF1F3F4);
  
  // Modern text colors
  static const Color textPrimary = Color(0xFF1B365D);
  static const Color textSecondary = Color(0xFF6B7C93);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  
  // Modern border and divider colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color divider = Color(0xFFF3F4F6);
  
  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Spacing scale (8px base)
  static const double spacing2xs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;
  static const double spacing3xl = 64.0;
  
  // Border radius scale
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 24.0;
  
  // Elevation scale
  static const double elevationNone = 0.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        brightness: Brightness.light,
        primary: primaryNavy,
        secondary: accentGold,
        tertiary: accentRed,
        surface: surfaceWhite,
        error: error,
      ),
      
      // Typography
      fontFamily: 'SF Pro Display',
      textTheme: _buildTextTheme(),
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
          size: 24,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          backgroundColor: Colors.transparent,
          elevation: 0,
          side: const BorderSide(color: borderMedium, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingMd),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundWhite,
        selectedItemColor: accentRed,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      
      // List tiles
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        minVerticalPadding: spacingSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
      ),
    );
  }
  
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.6,
        height: 1.3,
      ),
      
      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      
      // Title styles
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      
      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.2,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        letterSpacing: 0.3,
        height: 1.6,
      ),
      
      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.2,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
    );
  }

  // Modern helper widgets
  static Widget modernCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLg),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(spacingLg),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget sectionHeader(String title, {String? subtitle, Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: spacingXs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // Legacy compatibility method
  static Widget buildSectionHeader(String title, {String? subtitle, Widget? action}) {
    return sectionHeader(title, subtitle: subtitle, action: action);
  }

  static Widget modernButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isPrimary = true,
    bool isDestructive = false,
    bool isFullWidth = false,
  }) {
    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? accentRed : primaryNavy,
            foregroundColor: Colors.white,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: isDestructive ? accentRed : primaryNavy,
            side: BorderSide(
              color: isDestructive ? accentRed : borderMedium,
              width: 1.5,
            ),
          );

    final button = icon != null
        ? (isPrimary
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: Text(text),
                style: buttonStyle,
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: Text(text),
                style: buttonStyle,
              ))
        : (isPrimary
            ? ElevatedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Text(text),
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Text(text),
              ));

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: surfaceGray,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: textTertiary,
              ),
            ),
            const SizedBox(height: spacingLg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacingSm),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: spacingLg),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // Legacy compatibility colors
  static const Color cardWhite = surfaceWhite;
  static const Color textDark = textPrimary;
  static const Color textLight = textSecondary;
  static const Color successGreen = success;
}
