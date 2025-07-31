import 'package:flutter/material.dart';

import 'package:eagle_match/screens/tabs/account_screen.dart';
import 'package:eagle_match/screens/tabs/find_screen.dart';
import 'package:eagle_match/screens/tabs/create_screen.dart';
import 'package:eagle_match/screens/tabs/matches_screen.dart';
import 'package:eagle_match/screens/tabs/duos_screen.dart';
import '../../theme/usga_theme.dart';
import '../../theme/theme_manager.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;
  final ThemeManager _themeManager = ThemeManager();

static final List<Widget> _screens = <Widget>[
  const FindScreen(),
  const CreateScreen(),
  const MatchesScreen(),
  const DuosScreen(),
  const AccountScreen(),
];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeManager,
      builder: (context, child) {
        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: USGATheme.adaptiveSurface(_themeManager.isDarkMode),
              boxShadow: [
                BoxShadow(
                  color: USGATheme.primaryNavy.withValues(alpha: _themeManager.isDarkMode ? 0.2 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: USGATheme.accentRed,
              unselectedItemColor: USGATheme.adaptiveTextTertiary(_themeManager.isDarkMode),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Find',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  label: 'Create',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  label: 'Matches',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  label: 'Duos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Account',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}