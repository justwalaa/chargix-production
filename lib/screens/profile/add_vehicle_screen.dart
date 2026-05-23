import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import '../../models/vehicle_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';

/// Driver vehicle onboarding — plate, model, manufacturer, connector.
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  String _connector = 'CCS2';
  bool _saving = false;

  static const _connectors = ['CCS2', 'CHAdeMO', 'Type 2', 'Tesla'];

  @override
  void dispose() {
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    setState(() => _saving = true);
    final vehicle = VehicleModel(
      id: 'veh_${uid}_${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      licensePlate: _plateCtrl.text.trim(),
      connectorType: _connector,
      isDefault: true,
      createdAt: DateTime.now(),
    );
    final result = await ChargixData.vehicles.saveVehicle(vehicle);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (result is DataSuccess<void>) {
      Navigator.of(context).pop();
    } else if (result is DataError<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${result.errorOrNull}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add vehicle')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            children: [
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _plateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'License plate *',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _makeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer *',
                        hintText: 'Tesla, BMW, BYD…',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _modelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Model *',
                        hintText: 'Model 3, i4…',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Charging connector',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: _connectors
                          .map(
                            (c) => ButtonSegment<String>(
                              value: c,
                              label: Text(c, style: const TextStyle(fontSize: 11)),
                            ),
                          )
                          .toList(),
                      selected: {_connector},
                      onSelectionChanged: (s) {
                        setState(() => _connector = s.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
