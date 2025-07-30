import 'package:flutter/material.dart';

class USGATheme {
  // USGA-inspired color palette
  static const Color primaryNavy = Color(0xFF1B365D);      // USGA Navy Blue
  static const Color secondaryNavy = Color(0xFF2C4F70);    // Lighter Navy
  static const Color accentGold = Color(0xFFD4AF37);       // USGA Gold
  static const Color accentRed = Color(0xFFCC2936);        // USGA Red
  static const Color lightRed = Color(0xFFE8384F);         // Lighter USGA Red
  static const Color backgroundWhite = Color(0xFFFAFAFA);  // Off-white background
  static const Color textDark = Color(0xFF1B365D);         // Dark navy text
  static const Color textLight = Color(0xFF6B7C93);        // Light navy text
  static const Color successGreen = Color(0xFF2E7D32);     // Golf green
  static const Color cardWhite = Color(0xFFFFFFFF);        // Pure white cards
  static const Color borderLight = Color(0xFFE0E6ED);      // Light borders
  static const Color dividerColor = Color(0xFFEEF2F6);     // Subtle dividers

  static ThemeData get theme {
    return ThemeData(
      primarySwatch: MaterialColor(primaryNavy.value, {
        50: primaryNavy.withOpacity(0.1),
        100: primaryNavy.withOpacity(0.2),
        200: primaryNavy.withOpacity(0.3),
        300: primaryNavy.withOpacity(0.4),
        400: primaryNavy.withOpacity(0.5),
        500: primaryNavy,
        600: primaryNavy.withOpacity(0.7),
        700: primaryNavy.withOpacity(0.8),
        800: primaryNavy.withOpacity(0.9),
        900: primaryNavy,
      }),
      primaryColor: primaryNavy,
      scaffoldBackgroundColor: backgroundWhite,
      fontFamily: 'Inter', // Clean, professional font
      
      // AppBar Theme - USGA style
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card Theme - Clean white cards with subtle shadows
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: primaryNavy.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderLight, width: 1),
        ),
      ),

      // Button Themes - USGA style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          side: const BorderSide(color: primaryNavy, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentRed,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
        labelStyle: const TextStyle(
          color: textLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: textLight,
        ),
      ),

      // Text Themes - USGA typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textDark,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDark,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textDark,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textDark,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textLight,
          height: 1.4,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryNavy,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
    );
  }

  // Custom widget builders for USGA-style components
  static Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? primaryNavy).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color ?? primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color ?? primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textLight,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (color ?? primaryNavy).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color ?? primaryNavy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Red-themed action button for important actions
  static Widget redActionButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool outlined = false,
  }) {
    return outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
            label: Text(text),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentRed,
              side: const BorderSide(color: accentRed, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
            label: Text(text),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          );
  }

  // Red alert/error container
  static Widget errorContainer({
    required String message,
    IconData icon = Icons.error_outline,
    VoidCallback? onDismiss,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accentRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: accentRed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // Red accent chip/badge
  static Widget redChip({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accentRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
