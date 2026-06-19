import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import '../../models/vehicle_model.dart';

const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

TextStyle _sg(double size, FontWeight w,
    {Color color = _ink, double ls = 0}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

TextStyle _dm(double size, FontWeight w, {Color color = _ink}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color);

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
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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
    if (!mounted) return;
    setState(() => _saving = false);

    if (result is DataSuccess<void>) {
      Navigator.of(context).pop();
    } else if (result is DataError<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: ${result.errorOrNull}',
              style: _dm(13, FontWeight.w500, color: Colors.white)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

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
                    child: Text('Add Vehicle',
                        style: _sg(17, FontWeight.w700))),
              ],
            ),
          ),
          Container(height: 0.8, color: const Color(0xFFE5E7EB)),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomPad),
                children: [
                  // Vehicle icon header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _greenSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(PhosphorIconsFill.car,
                          color: _greenDark, size: 34),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 360.ms)
                      .scale(begin: const Offset(0.7, 0.7),
                          duration: 360.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vehicle details',
                            style: _sg(15, FontWeight.w800, ls: -0.2)),
                        const SizedBox(height: 16),

                        _FormField(
                          controller: _plateCtrl,
                          label: 'License plate',
                          hint: 'e.g. 12-A-3456',
                          icon: PhosphorIconsRegular.identificationCard,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        _FormField(
                          controller: _makeCtrl,
                          label: 'Manufacturer',
                          hint: 'Tesla, BMW, BYD…',
                          icon: PhosphorIconsRegular.factory,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        _FormField(
                          controller: _modelCtrl,
                          label: 'Model',
                          hint: 'Model 3, i4…',
                          icon: PhosphorIconsRegular.car,
                          isRequired: true,
                        ),

                        const SizedBox(height: 20),

                        Text('Charging connector',
                            style: _dm(13, FontWeight.w600, color: _slate)),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _connectors.map((c) {
                            final selected = _connector == c;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _connector = c),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _greenSurface
                                      : const Color(0xFFF3F4F6),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? _green
                                        : _border,
                                    width:
                                        selected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? _greenDark
                                        : _slate,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 60.ms, duration: 340.ms)
                      .slideY(begin: 0.06, end: 0, delay: 60.ms,
                          duration: 340.ms, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // Save button
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 54,
                      decoration: BoxDecoration(
                        color: _saving
                            ? const Color(0xFFE5E7EB)
                            : _green,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _saving
                            ? []
                            : [
                                BoxShadow(
                                  color: _green.withValues(alpha: 0.32),
                                  blurRadius: 18,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      child: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        _green.withValues(alpha: 0.6)),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    PhosphorIconsRegular.floppyDisk,
                                    color: Colors.white,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text('Save vehicle',
                                    style: _sg(15, FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 320.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isRequired = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: _slate),
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFD1D5DB)),
        prefixIcon: Icon(icon, size: 18, color: _slate),
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      validator: isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
