import 'package:flutter/material.dart';

import 'station_bookings_screen.dart';
import 'station_dashboard_screen.dart';
import 'station_slots_screen.dart';
import '../settings/settings_screen.dart';

/// Station-operator shell (separate from driver [MainNavigation]).
class StationMainNavigation extends StatefulWidget {
  const StationMainNavigation({
    super.key,
    required this.stationId,
  });

  final String stationId;

  @override
  State<StationMainNavigation> createState() => _StationMainNavigationState();
}

class _StationMainNavigationState extends State<StationMainNavigation> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      StationDashboardScreen(stationId: widget.stationId),
      StationBookingsScreen(stationId: widget.stationId),
      StationSlotsScreen(stationId: widget.stationId),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Slots',
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
