import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/vehicle_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/empty_state.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';
import 'add_vehicle_screen.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My vehicles')),
        body: const ChargixEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in required',
          message: 'Add vehicles after logging in with your phone.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const AddVehicleScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vehicle'),
      ),
      body: FirebaseStreamView<List<VehicleModel>>(
        stream: ChargixData.vehicles.watchVehiclesForUser(uid),
        emptyIcon: Icons.electric_car_outlined,
        emptyTitle: 'No vehicles yet',
        emptyMessage: 'Add your EV to get better charging recommendations.',
        builder: (context, vehicles) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: vehicles.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final v = vehicles[index];
              return PremiumCard(
                child: Row(
                  children: [
                    Icon(Icons.electric_car_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.displayLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${v.connectorType}${v.licensePlate != null ? ' · ${v.licensePlate}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (v.isDefault)
                      const Chip(
                        label: Text('Default'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
