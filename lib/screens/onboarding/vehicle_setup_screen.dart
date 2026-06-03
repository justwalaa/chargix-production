// lib/screens/onboarding/vehicle_setup_screen.dart
//
// NEW FILE — create at: lib/screens/onboarding/vehicle_setup_screen.dart
//
// Shows once on first launch (after onboarding) if the driver has no vehicles.
// Reuses the exact same save logic as AddVehicleScreen.
// Has a "Skip for now" option — non-blocking.
// Calls [onComplete] when done (saved or skipped) so the caller
// can push MainNavigation.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import '../../models/vehicle_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';

class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({super.key, required this.onComplete});

  /// Called when the driver saves a vehicle OR taps "Skip for now".
  final VoidCallback onComplete;

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String _connector = 'CCS2';
  bool _saving = false;

  static const _connectors = ['CCS2', 'CHAdeMO', 'Type 2', 'Tesla'];

  // Popular EV make shortcuts so demo flows fast
  static const _quickMakes = ['Tesla', 'BMW', 'BYD', 'Hyundai', 'Kia', 'Audi'];

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      widget.onComplete();
      return;
    }

    setState(() => _saving = true);

    final vehicle = VehicleModel(
      id: 'veh_${uid}_${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      licensePlate: _plateCtrl.text.trim().isEmpty
          ? null
          : _plateCtrl.text.trim(),
      connectorType: _connector,
      isDefault: true,
      createdAt: DateTime.now(),
    );

    final result = await ChargixData.vehicles.saveVehicle(vehicle);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result is DataSuccess<void>) {
      // Small success moment before proceeding
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 10),
              Text(
                '${_makeCtrl.text.trim()} ${_modelCtrl.text.trim()} added!',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.bg3,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
        ),
      );
      // Brief pause so the snackbar is visible, then proceed
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) widget.onComplete();
    } else if (result is DataError<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Could not save vehicle: ${result.errorOrNull}'),
          backgroundColor: AppColors.red.withAlpha(200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _skip() => widget.onComplete();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg1,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenGutter, 24,
                        AppSpacing.screenGutter, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Skip button top-right
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _skip,
                            child: const Text(
                              'Skip for now',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.cyan, AppColors.violet],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withAlpha(60),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.electric_car_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Headline
                        const Text(
                          "What's your EV?",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Adding your vehicle helps Chargix show compatible '
                          'chargers and autofill bookings.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),

                // ── Quick-pick make buttons ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenGutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUICK SELECT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickMakes.map((make) {
                            final isSelected = _makeCtrl.text == make;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _makeCtrl.text = make),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.cyan.withAlpha(20)
                                      : AppColors.bg3,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.lg),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.cyan.withAlpha(120)
                                        : AppColors.border2,
                                    width: isSelected ? 1.5 : 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check_rounded,
                                          size: 14,
                                          color: AppColors.cyan),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      make,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.cyan
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),

                // ── Form card ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenGutter),
                    child: PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Make field
                          TextFormField(
                            controller: _makeCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Manufacturer *',
                              hintText: 'Tesla, BMW, BYD…',
                              prefixIcon:
                                  Icon(Icons.business_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter the manufacturer'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Model field
                          TextFormField(
                            controller: _modelCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Model *',
                              hintText: 'Model 3, i4, Ioniq 6…',
                              prefixIcon:
                                  Icon(Icons.electric_car_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter the model'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Plate (optional)
                          TextFormField(
                            controller: _plateCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'License plate (optional)',
                              hintText: 'e.g. 12-3456',
                              prefixIcon:
                                  Icon(Icons.pin_outlined),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Connector type label
                          const Text(
                            'Charging connector',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Connector chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _connectors.map((c) {
                              final sel = c == _connector;
                              return ChoiceChip(
                                label: Text(c),
                                selected: sel,
                                onSelected: (_) =>
                                    setState(() => _connector = c),
                                selectedColor:
                                    AppColors.cyan.withAlpha(25),
                                labelStyle: TextStyle(
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: sel
                                      ? AppColors.cyan
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: sel
                                      ? AppColors.cyan.withAlpha(100)
                                      : AppColors.border2,
                                  width: sel ? 1.5 : 0.8,
                                ),
                                showCheckmark: false,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom padding for button ──────────────────────────────
                const SliverToBoxAdapter(
                    child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),

        // ── Sticky save button ─────────────────────────────────────────────
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            12,
            AppSpacing.screenGutter,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: AppColors.bg1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.bg1),
                          ),
                        )
                      : const Text('Add my vehicle'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _skip,
                child: const Text(
                  "I'll add it later",
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}