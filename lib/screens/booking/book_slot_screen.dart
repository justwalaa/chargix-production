import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/main_tab_scope.dart';
import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import 'package:chargix_production/models/booking_model.dart';
import '../../models/station_model.dart';
import '../../models/station_slot_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/map/station_type_badge.dart';
import '../../models/map_station.dart';
import '../../models/partner_map_data.dart';

/// Driver flow: pick slot + time → atomic Firestore reservation.
class BookSlotScreen extends StatefulWidget {
  const BookSlotScreen({super.key, required this.station});

  final StationModel station;

  @override
  State<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends State<BookSlotScreen> {
  StationSlotModel? _selectedSlot;
  DateTime _start = DateTime.now().add(const Duration(minutes: 45));
  bool _submitting = false;

MapStation get _mapStation => MapStation.partner(
          id: widget.station.id,
        name: widget.station.name,
        address: widget.station.address,
        latitude: widget.station.latitude,
        longitude: widget.station.longitude,
        partner: PartnerMapData(station: widget.station),
      );

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final slot = _selectedSlot;
    if (uid == null || slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a charger bay first')),
      );
      return;
    }
    setState(() => _submitting = true);
    final end = _start.add(const Duration(hours: 1));
    final result = await ChargixData.bookings.reserveSlot(
      userId: uid,
      station: widget.station,
      slot: slot,
      scheduledStart: _start,
      scheduledEnd: end,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (result is DataSuccess<BookingModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking submitted — awaiting station approval'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      MainTabScope.goTo(context, MainTabIndex.bookings);
    } else if (result is DataError<BookingModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.errorOrNull}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;

    return Scaffold(
      appBar: AppBar(title: const Text('Book charging session')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenGutter),
              children: [
                StationTypeBadge(station: _mapStation),
                const SizedBox(height: AppSpacing.md),
                Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(station.address),
                const SizedBox(height: AppSpacing.lg),
                PremiumCard(
                  onTap: _pickStart,
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start time',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(_start.toLocal().toString()),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Select charger bay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FirebaseStreamView<List<StationSlotModel>>(
                  stream: ChargixData.stationOwner.watchSlots(station.id),
                  emptyTitle: 'No bays configured',
                  emptyMessage: 'Station operator must add slots first.',
                  builder: (context, slots) {
                    final available =
                        slots.where((s) => s.isAvailable).toList();
                    if (available.isEmpty) {
                      return const Text('All bays are currently reserved.');
                    }
                    return Column(
                      children: available.map((slot) {
                        final selected = _selectedSlot?.id == slot.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: PremiumCard(
                            onTap: () => setState(() => _selectedSlot = slot),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${slot.connectorType} · ${slot.powerKw.round()} kW',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.screenGutter),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Request booking'),
            ),
          ),
        ],
      ),
    );
  }
}
