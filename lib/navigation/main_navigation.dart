// lib/navigation/main_navigation.dart
//
// Driver shell: Home → Map → Activity → Profile

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chargix_production/core/navigation/main_tab_scope.dart';
import 'package:chargix_production/screens/home/home_screen.dart';
import 'package:chargix_production/screens/map/map_screen.dart';
import 'package:chargix_production/screens/profile/profile_screen.dart';
import 'package:chargix_production/screens/booking/booking_screen.dart';
import 'package:chargix_production/theme/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = MainTabIndex.home;

  static final List<Widget> _tabs = const [
    HomeScreen(),
    MapScreen(),
    BookingScreen(),
    ProfileScreen(),
  ];

  void _goToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    final electric = Theme.of(context).colorScheme.primary;
    const inactive = AppColors.textMuted;

    return MainTabScope(
      goToTab: _goToTab,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _ChargixNavBar(
          currentIndex: _currentIndex,
          onTap: _goToTab,
          electricColor: electric,
          inactiveColor: inactive,
        ),
      ),
    );
  }
}

class _ChargixNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color electricColor;
  final Color inactiveColor;

  const _ChargixNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.electricColor,
    required this.inactiveColor,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.map_rounded, label: 'Map'),
    _NavItem(icon: Icons.history_rounded, label: 'Activity'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      height: 68 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(color: electricColor.withAlpha(30), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: electricColor.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          _items.length,
          (i) => _NavButton(
            item: _items[i],
            isSelected: i == currentIndex,
            activeColor: electricColor,
            inactiveColor: inactiveColor,
            onTap: () => onTap(i),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withAlpha(80),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                item.icon,
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
