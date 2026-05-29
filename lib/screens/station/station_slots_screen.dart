import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/station_slot_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../utils/currency_format.dart';
import '../../utils/slot_availability.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/station/station_slot_editor_sheet.dart';

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
          SlotAvailability.compute(slots, logTag: 'SlotSync');
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: slots.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final slot = slots[index];
              final scheme = Theme.of(context).colorScheme;
              return PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          !slot.isOpen
                              ? Icons.lock_rounded
                              : slot.isAvailable
                                  ? Icons.check_circle_rounded
                                  : Icons.pause_circle_rounded,
                          color: !slot.isOpen
                              ? scheme.error
                              : slot.isAvailable
                                  ? scheme.primary
                                  : scheme.outline,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${slot.chargingType} · ${slot.connectorType} · '
                                '${slot.powerKw.toStringAsFixed(0)} kW',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (slot.pricePerKwh != null)
                                Text(
                                  CurrencyFormat.perKwh(slot.pricePerKwh!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: scheme.primary),
                                ),
                              Text(
                                '~${slot.estimatedDurationMinutes} min · '
                                '${slot.isOpen ? (slot.isAvailable ? "Open" : "Unavailable") : "Closed"}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              if (slot.notes != null && slot.notes!.isNotEmpty)
                                Text(
                                  slot.notes!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () => _editSlot(context, slot),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _toggleOpen(context, slot),
                            child: Text(slot.isOpen ? 'Close bay' : 'Open bay'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: slot.isOpen
                                ? () => _toggleAvailability(context, slot)
                                : null,
                            child: Text(
                              slot.isAvailable ? 'Mark busy' : 'Mark available',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editStationPricing(context),
        icon: const Icon(Icons.price_change_rounded),
        label: const Text('Station pricing (JOD)'),
      ),
    );
  }

  Future<void> _addSlot(BuildContext context) async {
    final id = '${stationId}_slot_${DateTime.now().millisecondsSinceEpoch}';
    final draft = StationSlotModel(
      id: id,
      stationId: stationId,
      label: 'Bay ${DateTime.now().millisecondsSinceEpoch % 100}',
      pricePerKwh: 0.35,
    );
    final saved = await StationSlotEditorSheet.show(
      context,
      initial: draft,
      isCreate: true,
    );
    if (saved == null || !context.mounted) return;
    await ChargixData.stationOwner.saveSlot(saved);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Charging bay added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editSlot(BuildContext context, StationSlotModel slot) async {
    final saved = await StationSlotEditorSheet.show(
      context,
      initial: slot,
      isCreate: false,
    );
    if (saved == null || !context.mounted) return;
    await ChargixData.stationOwner.saveSlot(saved);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bay updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleOpen(BuildContext context, StationSlotModel slot) async {
    final nextOpen = !slot.isOpen;
    await ChargixData.stationOwner.saveSlot(
      slot.copyWith(
        isOpen: nextOpen,
        isAvailable: nextOpen ? slot.isAvailable : false,
      ),
    );
  }

  Future<void> _toggleAvailability(
    BuildContext context,
    StationSlotModel slot,
  ) async {
    await ChargixData.stationOwner.saveSlot(
      slot.copyWith(isAvailable: !slot.isAvailable),
    );
  }

  Future<void> _editStationPricing(BuildContext context) async {
    final priceCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Station default price'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Price per kWh (${CurrencyFormat.code})',
            prefixText: '${CurrencyFormat.symbol} ',
            hintText: '0.350',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final price = double.tryParse(priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    await ChargixData.stationOwner.updateStationPricing(
      stationId: stationId,
      pricePerKwh: price,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Station price: ${CurrencyFormat.perKwh(price)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
