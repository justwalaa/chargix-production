import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/chargix/empty_state.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import 'add_vehicle_screen.dart';

const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final topPad = MediaQuery.paddingOf(context).top;

    if (uid == null) {
      return Scaffold(
        backgroundColor: _canvas,
        body: const ChargixEmptyState(
          icon: PhosphorIconsRegular.lockSimple,
          title: 'Sign in required',
          message: 'Add vehicles after logging in with your phone.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowLeft,
                      color: _ink, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text('My Vehicles',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                        builder: (_) => const AddVehicleScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.plus,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text('Add',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),
          Expanded(
            child: FirebaseStreamView<List<VehicleModel>>(
              stream: ChargixData.vehicles.watchVehiclesForUser(uid),
              emptyIcon: PhosphorIconsRegular.car,
              emptyTitle: 'No vehicles yet',
              emptyMessage:
                  'Add your EV to get better charging recommendations.',
              builder: (context, vehicles) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final v = vehicles[i];
                    return _DismissibleVehicleTile(
                      vehicle: v,
                      allVehicles: vehicles,
                    )
                        .animate()
                        .fadeIn(delay: (60 * i).ms, duration: 280.ms)
                        .slideY(
                            begin: 0.05,
                            end: 0,
                            delay: (60 * i).ms,
                            duration: 280.ms,
                            curve: Curves.easeOut);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissibleVehicleTile extends StatelessWidget {
  const _DismissibleVehicleTile({
    required this.vehicle,
    required this.allVehicles,
  });

  final VehicleModel vehicle;
  final List<VehicleModel> allVehicles;

  Future<void> _delete(BuildContext context) async {
    final isLast = allVehicles.length == 1;

    if (isLast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete your only vehicle.',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: Colors.white)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove vehicle?',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
              const SizedBox(height: 8),
              Text(
                'Remove ${vehicle.displayLabel} from your account?',
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _slate,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Keep',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _ink)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Remove',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ChargixData.vehicles.deleteVehicle(vehicle.id);

    // If this was the default, promote the next available vehicle
    if (vehicle.isDefault) {
      final remaining =
          allVehicles.where((v) => v.id != vehicle.id).toList();
      if (remaining.isNotEmpty) {
        await ChargixData.vehicles.saveVehicle(
          remaining.first.copyWith(isDefault: true),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(vehicle.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _delete(context);
        return false; // we handle deletion ourselves
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(PhosphorIconsRegular.trash,
            color: Color(0xFFDC2626), size: 22),
      ),
      child: _VehicleTile(vehicle: vehicle),
    );
  }
}

// Need copyWith on VehicleModel — uses a local extension
extension _VehicleCopyWith on VehicleModel {
  VehicleModel copyWith({bool? isDefault}) => VehicleModel(
        id: id,
        userId: userId,
        make: make,
        model: model,
        year: year,
        batteryCapacityKwh: batteryCapacityKwh,
        connectorType: connectorType,
        licensePlate: licensePlate,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: vehicle.isDefault ? _green : _border,
            width: vehicle.isDefault ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _greenSurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(PhosphorIconsFill.car,
                color: _greenDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayLabel,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    vehicle.connectorType,
                    if (vehicle.licensePlate != null)
                      vehicle.licensePlate!,
                  ].join(' · '),
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _slate),
                ),
              ],
            ),
          ),
          if (vehicle.isDefault)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _greenSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Default',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _greenDark)),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(PhosphorIconsRegular.trash,
                  size: 14, color: Color(0xFFDC2626)),
            ),
        ],
      ),
    );
  }
}
