// lib/navigation/main_navigation.dart
//
// Production bottom-navigation shell for Chargix.
// All four tabs wired to REAL existing screens – NO placeholders remain.
//
// Tab order:
//   0 – Map       → MapScreen        (working, unchanged)
//   1 – Stations  → StationsScreen
//   2 – Activity  → BookingsScreen
//   3 – Profile   → ProfileScreen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chargix_production/screens/map/map_screen.dart';
import 'package:chargix_production/screens/profile/profile_screen.dart';

import '../screens/booking/booking_screen.dart';
import '../screens/stations/stations_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const _bgColor  = Color(0xFF080B14);
  static const _electric = Color(0xFF00D4FF);
  static const _inactive = Color(0xFF2E4060);

  // IndexedStack keeps all tabs alive in memory so state is preserved
  // when switching tabs (e.g. map camera position, scroll offsets).
  static final List<Widget> _tabs = const [
    MapScreen(),       // 0 – Map
    StationsScreen(),  // 1 – Stations
    BookingScreen(),  // 2 – Activity / Bookings
    ProfileScreen(),   // 3 – Profile
  ];

  @override
  Widget build(BuildContext context) {
    // Keep status-bar icons light on the dark background.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _ChargixNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        electricColor: _electric,
        inactiveColor: _inactive,
      ),
    );
  }
}

// ── Custom bottom nav bar ──────────────────────────────────────────────────

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
    _NavItem(icon: Icons.map_rounded,         label: 'Map'),
    _NavItem(icon: Icons.ev_station_rounded,  label: 'Stations'),
    _NavItem(icon: Icons.history_rounded,     label: 'Activity'),
    _NavItem(icon: Icons.person_rounded,      label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1C),
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
                  )
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
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
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
