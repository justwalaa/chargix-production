import 'package:flutter/foundation.dart';

import '../models/station_slot_model.dart';

/// Aggregated bay counts derived from live slot documents.
class SlotAvailabilityStats {
  const SlotAvailabilityStats({
    required this.total,
    required this.open,
    required this.available,
    required this.booked,
    required this.driverVisible,
  });

  final int total;
  final int open;
  final int available;
  final int booked;
  final int driverVisible;

  static const empty = SlotAvailabilityStats(
    total: 0,
    open: 0,
    available: 0,
    booked: 0,
    driverVisible: 0,
  );
}

/// Operational slot counting — single source of truth for UI counters.
abstract final class SlotAvailability {
  static SlotAvailabilityStats compute(
    List<StationSlotModel> slots, {
    String? logTag,
  }) {
    final total = slots.length;
    var open = 0;
    var available = 0;
    var booked = 0;
    var driverVisible = 0;

    for (final slot in slots) {
      if (slot.isOpen) {
        open++;
        if (slot.isAvailable) {
          available++;
          driverVisible++;
        } else {
          booked++;
        }
      }
    }

    final stats = SlotAvailabilityStats(
      total: total,
      open: open,
      available: available,
      booked: booked,
      driverVisible: driverVisible,
    );

    final tag = logTag ?? 'SlotSync';
    debugPrint(
      '[$tag] total=$total open=$open available=$available '
      'booked=$booked driverVisible=$driverVisible',
    );
    debugPrint(
      '[Availability] ${stats.driverVisible}/${stats.total} bookable bays',
    );

    return stats;
  }

  static void logDriverSlots(
    List<StationSlotModel> slots,
    String stationId,
  ) {
    final visible = slots.where((s) => s.isOpen && s.isAvailable).toList();
    debugPrint(
      '[DriverSlots] station=$stationId visible=${visible.length} '
      'labels=${visible.map((s) => s.label).join(", ")}',
    );
  }
}
