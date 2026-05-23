import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/station_slot_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';

class StationSlotsScreen extends StatelessWidget {
  const StationSlotsScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slots & pricing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addSlot(context),
          ),
        ],
      ),
      body: FirebaseStreamView<List<StationSlotModel>>(
        stream: ChargixData.stationOwner.watchSlots(stationId),
        emptyTitle: 'No slots yet',
        emptyMessage: 'Add charging bays to accept reservations.',
        emptyActionLabel: 'Add slot',
        onEmptyAction: () => _addSlot(context),
        builder: (context, slots) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: slots.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final slot = slots[index];
              return PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      slot.isAvailable
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.label,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            '${slot.connectorType} · ${slot.powerKw.toStringAsFixed(0)} kW'
                            '${slot.pricePerKwh != null ? ' · \$${slot.pricePerKwh!.toStringAsFixed(2)}/kWh' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPricing(context),
        icon: const Icon(Icons.price_change_rounded),
        label: const Text('Station pricing'),
      ),
    );
  }

  Future<void> _addSlot(BuildContext context) async {
    final id = '${stationId}_slot_${DateTime.now().millisecondsSinceEpoch}';
    await ChargixData.stationOwner.saveSlot(
      StationSlotModel(
        id: id,
        stationId: stationId,
        label: 'New bay',
        pricePerKwh: 0.42,
      ),
    );
  }

  Future<void> _editPricing(BuildContext context) async {
    await ChargixData.stationOwner.updateStationPricing(
      stationId: stationId,
      pricePerKwh: 0.45,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Station price updated to \$0.45/kWh'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
