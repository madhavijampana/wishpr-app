import 'package:flutter/material.dart';

import 'contacts_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'phrases_screen.dart';
import 'settings_screen.dart';

/// Root scaffold with bottom navigation for the five main sections.
class WishprShell extends StatefulWidget {
  const WishprShell({super.key});

  @override
  State<WishprShell> createState() => _WishprShellState();
}

class _WishprShellState extends State<WishprShell> {
  int _index = 0;

  /// App bar titles (home uses in-content hero title instead).
  static const _appBarTitles = [
    '',
    'Secret Phrases',
    'Trusted Contacts',
    'Trigger History',
    'Settings',
  ];

  static const _bodies = <Widget>[
    HomeScreen(),
    PhrasesScreen(),
    ContactsScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _index == 0
          ? null
          : AppBar(
              title: Text(_appBarTitles[_index]),
            ),
      body: IndexedStack(
        index: _index,
        children: _bodies,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_quote_outlined),
            selectedIcon: Icon(Icons.format_quote_rounded),
            label: 'Phrases',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
