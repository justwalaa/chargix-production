import 'package:flutter/foundation.dart';

/// A repeating daily time window when a slot is available for booking.
/// e.g. "09:00 – 09:40" — repeats every day automatically.
///
/// [bookedDates] tracks which specific calendar dates are booked:
/// key = "yyyy-MM-dd", value = bookingId.
/// Client-side: only today and tomorrow are relevant (older entries are ignored).
@immutable
class SlotTimeWindow {
  const SlotTimeWindow({
    required this.id,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.bookedDates = const {},
  });

  final String id;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// Key = "yyyy-MM-dd", value = bookingId that locked this date.
  final Map<String, String> bookedDates;

  // ── Display helpers ───────────────────────────────────────────────────────

  String get startLabel =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endLabel =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  String get timeRangeLabel => '$startLabel – $endLabel';

  int get durationMinutes {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return (end - start).clamp(0, 1440);
  }

  // ── Booking helpers ───────────────────────────────────────────────────────

  bool isDateBooked(String dateKey) => bookedDates.containsKey(dateKey);

  /// Canonical "yyyy-MM-dd" key for a given date.
  static String dateKeyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'bookedDates': bookedDates,
      };

  factory SlotTimeWindow.fromMap(Map<String, dynamic> map) {
    final rawDates = map['bookedDates'];
    final Map<String, String> dates;
    if (rawDates is Map) {
      dates = rawDates.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      dates = const {};
    }
    return SlotTimeWindow(
      id: map['id'] as String? ?? 'tw_${map.hashCode.abs()}',
      startHour: (map['startHour'] as num?)?.toInt() ?? 9,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 10,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
      bookedDates: dates,
    );
  }

  SlotTimeWindow copyWith({
    String? id,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    Map<String, String>? bookedDates,
  }) {
    return SlotTimeWindow(
      id: id ?? this.id,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      bookedDates: bookedDates ?? this.bookedDates,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotTimeWindow &&
          id == other.id &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          endHour == other.endHour &&
          endMinute == other.endMinute;

  @override
  int get hashCode =>
      Object.hash(id, startHour, startMinute, endHour, endMinute);
}
