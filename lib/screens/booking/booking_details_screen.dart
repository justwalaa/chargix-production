import 'package:flutter/material.dart';
import '../../../../chargix_production/lib/models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({
    super.key,
    required this.booking,
    this.stationName,
  });

  final BookingModel booking;
  final String? stationName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String fmt(DateTime d) =>
        '${_weekday(d.weekday)}, ${_month(d.month)} ${d.day} · ${_pad(d.hour)}:${_pad(d.minute)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        children: [
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stationName ?? 'Station ${booking.stationId}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatusChip(status: booking.status),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumCard(
            child: Column(
              children: [
                if (booking.scheduledStart != null)
                  _Row(
                    icon: Icons.schedule_rounded,
                    label: 'Starts',
                    value: fmt(booking.scheduledStart!),
                  ),
                if (booking.scheduledEnd != null) ...[
                  const Divider(height: AppSpacing.lg),
                  _Row(
                    icon: Icons.event_available_rounded,
                    label: 'Ends',
                    value: fmt(booking.scheduledEnd!),
                  ),
                ],
                if (booking.portNumber != null) ...[
                  const Divider(height: AppSpacing.lg),
                  _Row(
                    icon: Icons.ev_station_outlined,
                    label: 'Port',
                    value: '#${booking.portNumber}',
                  ),
                ],
              ],
            ),
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            PremiumCard(
              child: Text(
                booking.notes!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _weekday(int w) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

String _month(int m) =>
    const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg = scheme.surfaceContainerHighest;
    Color fg = scheme.onSurface;
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.active:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
      case BookingStatus.cancelled:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
      default:
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
