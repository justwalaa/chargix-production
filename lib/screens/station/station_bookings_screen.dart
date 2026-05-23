import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import 'package:chargix_production/models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/chargix/status_badge.dart';

class StationBookingsScreen extends StatelessWidget {
  const StationBookingsScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservations')),
      body: FirebaseStreamView<List<BookingModel>>(
        stream: ChargixData.stationOwner.watchStationBookings(stationId),
        emptyIcon: Icons.inbox_outlined,
        emptyTitle: 'No reservations',
        emptyMessage: 'Incoming EV and shipment bookings will appear here.',
        builder: (context, bookings) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: bookings.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final b = bookings[index];
              return PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Booking ${b.id.substring(0, b.id.length.clamp(0, 8))}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        StatusBadge(
                          label: b.status.value,
                          color: _statusColor(b.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (b.scheduledStart != null)
                      Text(
                        'Starts: ${b.scheduledStart}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (b.status == BookingStatus.pending) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _respond(
                                context,
                                b,
                                BookingStatus.rejected,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _respond(
                                context,
                                b,
                                BookingStatus.approved,
                              ),
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.approved:
      case BookingStatus.confirmed:
      case BookingStatus.active:
        return AppColors.neonGreen;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.red;
      default:
        return AppColors.bg1;
    }
  }

  Future<void> _respond(
    BuildContext context,
    BookingModel booking,
    BookingStatus status,
  ) async {
    final result = await ChargixData.stationOwner.respondToBooking(
      booking: booking,
      status: status,
      rejectionReason:
          status == BookingStatus.rejected ? 'Unavailable slot' : null,
    );
    if (!context.mounted) {
      return;
    }
    final ok = result.isSuccess;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Booking updated' : 'Update failed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
