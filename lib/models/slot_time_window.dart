// lib/models/slot_time_window.dart
//
// NEW FILE — create at: lib/models/slot_time_window.dart
//
// Embedded time window inside a StationSlotModel.
// Stored as a List<Map> in Firestore under the slot document.
// No new collection needed — fully backward compatible.

import 'package:flutter/foundation.dart';

/// A repeating weekly time window when a slot is available for booking.
/// e.g. "Monday–Friday, 09:00–11:00"
@immutable
class SlotTimeWindow {
  const SlotTimeWindow({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.days = const [1, 2, 3, 4, 5, 6, 7], // 1=Mon … 7=Sun (ISO weekday)
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// ISO weekdays this window applies to. 1=Mon, 7=Sun.
  final List<int> days;

  // ── Display helpers ───────────────────────────────────────────────────────

  String get startLabel =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endLabel =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  String get timeRangeLabel => '$startLabel – $endLabel';

  String get daysLabel {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.every((d) => d <= 5)) return 'Mon – Fri';
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    }
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d]).join(', ');
  }

  String get fullLabel => '$daysLabel · $timeRangeLabel';

  // ── Concrete DateTime for a specific date ─────────────────────────────────

  /// Returns the start DateTime for this window on [date].
  DateTime startOn(DateTime date) =>
      DateTime(date.year, date.month, date.day, startHour, startMinute);

  /// Returns the end DateTime for this window on [date].
  DateTime endOn(DateTime date) =>
      DateTime(date.year, date.month, date.day, endHour, endMinute);

  /// Whether this window applies on [date]'s weekday.
  bool appliesToDate(DateTime date) => days.contains(date.weekday);

  /// Whether this window's start time is still in the future from [now].
  bool isUpcoming(DateTime date, DateTime now) {
    if (!appliesToDate(date)) return false;
    return startOn(date).isAfter(now);
  }

  // ── Duration ──────────────────────────────────────────────────────────────

  int get durationMinutes {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return end - start;
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'days': days,
      };

  factory SlotTimeWindow.fromMap(Map<String, dynamic> map) {
    return SlotTimeWindow(
      startHour: (map['startHour'] as num?)?.toInt() ?? 9,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 10,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
      days: (map['days'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
    );
  }

  SlotTimeWindow copyWith({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? days,
  }) {
    return SlotTimeWindow(
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      days: days ?? this.days,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotTimeWindow &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          endHour == other.endHour &&
          endMinute == other.endMinute;

  @override
  int get hashCode => Object.hash(startHour, startMinute, endHour, endMinute);
}