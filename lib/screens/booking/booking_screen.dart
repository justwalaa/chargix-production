import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/main_tab_scope.dart';
import '../../data/chargix_data.dart';
import 'package:chargix_production/models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/empty_state.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';
import 'booking_details_screen.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookings')),
        body: const ChargixEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in required',
          message: 'Log in with your phone number to view reservations.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: FirebaseStreamView<List<BookingModel>>(
        stream: ChargixData.bookings.watchBookingsForUser(uid),
        emptyIcon: Icons.calendar_month_outlined,
        emptyTitle: 'No bookings yet',
        emptyMessage:
            'Reserve a charger from Stations or Map to track sessions here.',
        emptyActionLabel: 'Browse stations',
        onEmptyAction: () => MainTabScope.goTo(context, MainTabIndex.map),
        builder: (context, bookings) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: bookings.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _BookingTile(
                booking: booking,
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => BookingDetailsScreen(booking: booking),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.onTap,
  });

  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = booking.scheduledStart;
    final subtitle = start != null
        ? '${start.day}/${start.month}/${start.year} · ${start.hour}:${start.minute.toString().padLeft(2, '0')}'
        : 'Station ${booking.stationId}';

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.local_shipping_rounded),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservation ${booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            booking.status.value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: booking.status == BookingStatus.cancelled
                      ? scheme.error
                      : scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
