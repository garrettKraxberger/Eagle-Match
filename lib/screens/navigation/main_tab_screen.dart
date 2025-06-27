import 'package:flutter/material.dart';

import 'package:eagle_match/screens/tabs/account_screen.dart';
import 'package:eagle_match/screens/tabs/find_screen.dart';
import 'package:eagle_match/screens/tabs/create_screen.dart';
import 'package:eagle_match/screens/tabs/matches_screen.dart';
import 'package:eagle_match/screens/tabs/duos_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

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
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Duos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}