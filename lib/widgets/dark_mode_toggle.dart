import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';
import '../theme/usga_theme.dart';

/// Dark mode toggle switch widget
class DarkModeToggle extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const DarkModeToggle({
    Key? key,
    required this.isDark,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: USGATheme.adaptiveTextPrimary(isDark),
      ),
      title: Text(
        'Dark Mode',
        style: TextStyle(
          color: USGATheme.adaptiveTextPrimary(isDark),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        isDark ? 'Switch to light mode' : 'Switch to dark mode',
        style: TextStyle(
          color: USGATheme.adaptiveTextSecondary(isDark),
        ),
      ),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: onChanged,
        activeColor: USGATheme.accentRed,
        inactiveTrackColor: USGATheme.adaptiveBorder(isDark),
      ),
      onTap: () => onChanged(!isDark),
    );
  }
}

/// Settings section widget for theme controls
class ThemeSettingsSection extends StatelessWidget {
  final bool isDark;

  const ThemeSettingsSection({
    Key? key,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        USGATheme.sectionHeader(
          'Appearance',
          subtitle: 'Customize your app experience',
          isDark: isDark,
        ),
        const SizedBox(height: USGATheme.spacingSm),
        USGATheme.modernCard(
          isDark: isDark,
          child: DarkModeToggle(
            isDark: isDark,
            onChanged: (value) {
              ThemeManager().setTheme(value);
            },
          ),
        ),
      ],
    );
  }
}
