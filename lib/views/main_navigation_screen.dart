import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import 'dashboard_screen.dart';
import 'control_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationScreen({super.key, required this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;

    final screens = [
      DashboardScreen(onOpenControls: () => setState(() => _currentIndex = 1)),
      const ControlScreen(),
      const AnalyticsScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F5E9),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Image.asset('assets/figma/dashboard.png',
                width: 21, height: 21),
            label: l10n.tr('nav_dashboard'),
          ),
          NavigationDestination(
            icon:
                Image.asset('assets/figma/controls.png', width: 21, height: 21),
            label: l10n.tr('nav_control'),
          ),
          NavigationDestination(
            icon: Image.asset('assets/figma/analytics.png',
                width: 21, height: 21),
            label: l10n.tr('nav_analytics'),
          ),
          NavigationDestination(
            icon:
                Image.asset('assets/figma/settings.png', width: 21, height: 21),
            label: l10n.tr('nav_settings'),
          ),
        ],
      ),
    );
  }
}
