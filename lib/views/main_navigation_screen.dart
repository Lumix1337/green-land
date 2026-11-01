import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';
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
      const DashboardScreen(),
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
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded, color: AppTheme.primary),
            label: l10n.tr('nav_dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune_rounded, color: AppTheme.primary),
            label: l10n.tr('nav_control'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded, color: AppTheme.primary),
            label: l10n.tr('nav_analytics'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded, color: AppTheme.primary),
            label: l10n.tr('nav_settings'),
          ),
        ],
      ),
    );
  }
}
