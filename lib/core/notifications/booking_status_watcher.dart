import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../services/notification_service.dart';

/// Shows local notifications when booking status changes (driver or station).
class BookingStatusWatcher extends StatefulWidget {
  const BookingStatusWatcher({
    super.key,
    required this.child,
    this.stationId,
  });

  final Widget child;
  final String? stationId;

  @override
  State<BookingStatusWatcher> createState() => _BookingStatusWatcherState();
}

class _BookingStatusWatcherState extends State<BookingStatusWatcher> {
  StreamSubscription<List<BookingModel>>? _sub;
  final Map<String, BookingStatus> _lastStatus = {};

  @override
  void initState() {
    super.initState();
    unawaited(NotificationService.instance.initialize());
    _bind();
  }

  void _bind() {
    _sub?.cancel();
    final stationId = widget.stationId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (stationId != null) {
      _sub = ChargixData.bookings
          .watchBookingsForStation(stationId)
          .listen(_onBookings);
      return;
    }
    if (uid != null) {
      _sub = ChargixData.bookings.watchBookingsForUser(uid).listen(_onBookings);
    }
  }

  void _onBookings(List<BookingModel> bookings) {
    for (final b in bookings) {
      final prev = _lastStatus[b.id];
      if (prev == null) {
        _lastStatus[b.id] = b.status;
        if (b.status == BookingStatus.pending && widget.stationId != null) {
          final when = b.scheduledStart != null
              ? ' · ${b.scheduledStart!.toLocal()}'
              : '';
          unawaited(
            NotificationService.instance.showBookingNotification(
              title: 'New booking request',
              body: 'A driver requested a charging slot$when. Tap Bookings to respond.',
            ),
          );
        }
        continue;
      }
      if (prev == b.status) continue;
      _lastStatus[b.id] = b.status;
      _notifyTransition(b);
    }
  }

  void _notifyTransition(BookingModel b) {
    if (widget.stationId != null) return;
    final message = switch (b.status) {
      BookingStatus.approved ||
      BookingStatus.confirmed =>
        'Your booking was confirmed.',
      BookingStatus.rejected => 'Your booking was declined.',
      BookingStatus.active => 'Charging session started.',
      BookingStatus.completed => 'Charging session completed.',
      BookingStatus.cancelled => 'Your booking was cancelled.',
      _ => null,
    };
    if (message == null) return;
    unawaited(
      NotificationService.instance.showBookingNotification(
        title: 'Booking update',
        body: message,
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
