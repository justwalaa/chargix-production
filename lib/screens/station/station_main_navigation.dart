import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/notifications/booking_status_watcher.dart';
import '../../data/chargix_data.dart';
import '../../models/enums/booking_status.dart';
import 'station_bookings_screen.dart';
import 'station_dashboard_screen.dart';
import 'station_slots_screen.dart';
import '../settings/settings_screen.dart';

const _green = Color(0xFF22C55E);
const _slate = Color(0xFF6B7280);

/// Station-operator shell (separate from driver [MainNavigation]).
class StationMainNavigation extends StatefulWidget {
  const StationMainNavigation({super.key, required this.stationId});
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

    return BookingStatusWatcher(
      stationId: widget.stationId,
      child: Scaffold(
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDCFCE7),
          surfaceTintColor: Colors.transparent,
          destinations: [
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.gauge, color: const Color(0xFF6B7280)),
              selectedIcon: Icon(PhosphorIconsFill.gauge, color: _green),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: StreamBuilder<int>(
                stream: ChargixData.stationOwner
                    .watchStationBookings(widget.stationId)
                    .map((list) => list
                        .where((b) => b.status == BookingStatus.pending)
                        .length),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return _BadgedIcon(
                    icon: PhosphorIconsRegular.calendarBlank,
                    count: count,
                    selected: false,
                  );
                },
              ),
              selectedIcon: StreamBuilder<int>(
                stream: ChargixData.stationOwner
                    .watchStationBookings(widget.stationId)
                    .map((list) => list
                        .where((b) => b.status == BookingStatus.pending)
                        .length),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return _BadgedIcon(
                    icon: PhosphorIconsFill.calendarBlank,
                    count: count,
                    selected: true,
                  );
                },
              ),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.plugsConnected, color: const Color(0xFF6B7280)),
              selectedIcon: Icon(PhosphorIconsFill.plugsConnected, color: _green),
              label: 'Slots',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.gear, color: const Color(0xFF6B7280)),
              selectedIcon: Icon(PhosphorIconsFill.gear, color: _green),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.count,
    required this.selected,
  });
  final IconData icon;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: selected ? _green : _slate),
        if (count > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
