import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/routing/session_gate.dart';
import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import '../../models/operating_hours_model.dart';
import '../../models/picked_station_location.dart';
import '../../models/station_registration_draft.dart';
import '../auth/station_location_picker_screen.dart';
import '../../theme/tokens/tokens.dart';

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

TextStyle _dm(double size, FontWeight w, {Color color = _ink, double? h}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: h);

/// 3-step partner station registration (Firestore pending approval).
class StationOwnerOnboardingScreen extends StatefulWidget {
  const StationOwnerOnboardingScreen({
    super.key,
    required this.ownerUserId,
    this.phoneE164,
  });

  final String ownerUserId;
  final String? phoneE164;

  @override
  State<StationOwnerOnboardingScreen> createState() =>
      _StationOwnerOnboardingScreenState();
}

class _StationOwnerOnboardingScreenState
    extends State<StationOwnerOnboardingScreen> {
  final _page = PageController();
  int _step = 0;
  bool _submitting = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _stationNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openCtrl = TextEditingController(text: '08:00');
  final _closeCtrl = TextEditingController(text: '22:00');
  final _managerCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _backupCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();

  PickedStationLocation? _pickedLocation;

  @override
  void dispose() {
    _page.dispose();
    for (final c in [
      _emailCtrl, _passwordCtrl, _confirmCtrl, _stationNameCtrl,
      _cityCtrl, _addressCtrl, _openCtrl, _closeCtrl, _managerCtrl,
      _nationalIdCtrl, _backupCtrl, _logoUrlCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<PickedStationLocation>(
      MaterialPageRoute(
        builder: (_) =>
            StationLocationPickerScreen(initial: _pickedLocation),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pickedLocation = picked;
      if (_addressCtrl.text.trim().isEmpty) {
        _addressCtrl.text = picked.formattedAddress;
      }
    });
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _page.nextPage(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    } else {
      unawaited(_submit());
    }
  }

  Future<void> _submit() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match');
      return;
    }
    setState(() => _submitting = true);
    if (_pickedLocation == null) {
      _snack('Set your station location on the map.');
      setState(() => _submitting = false);
      return;
    }

    final loc = _pickedLocation!;
    final draft = StationRegistrationDraft(
      stationName: _stationNameCtrl.text.trim(),
      contactEmail: _emailCtrl.text.trim(),
      contactPhone: widget.phoneE164 ?? '',
      city: _cityCtrl.text.trim(),
      address: loc.formattedAddress.isNotEmpty
          ? loc.formattedAddress
          : _addressCtrl.text.trim(),
      latitude: loc.latitude,
      longitude: loc.longitude,
      operatingHours: OperatingHoursModel(
        openTime: _openCtrl.text.trim(),
        closeTime: _closeCtrl.text.trim(),
      ),
      managerName: _managerCtrl.text.trim(),
      managerNationalId: _nationalIdCtrl.text.trim().isEmpty
          ? null
          : _nationalIdCtrl.text.trim(),
      backupContactPhone: _backupCtrl.text.trim().isEmpty
          ? null
          : _backupCtrl.text.trim(),
      logoUrl: _logoUrlCtrl.text.trim().isEmpty
          ? null
          : _logoUrlCtrl.text.trim(),
    );

    final result = await ChargixData.stationOwner.submitPartnerRegistration(
      ownerUserId: widget.ownerUserId,
      draft: draft,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is DataSuccess<String>) {
      final home = await SessionGate.resolveHome();
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => home),
        (_) => false,
      );
    } else if (result is DataError<String>) {
      _snack('Submit failed: ${result.errorOrNull}');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: _dm(13, FontWeight.w500, color: Colors.white)),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: _ink, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Register station (${_step + 1}/3)',
                        style: _sg(17, FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Step progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 3,
                    minHeight: 4,
                    backgroundColor: _border,
                    valueColor: const AlwaysStoppedAnimation(_green),
                  ),
                ),
              ],
            ),
          ),

          // ── Pages ──────────────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stepAccount(context),
                _stepStation(context),
                _stepVerification(context),
              ],
            ),
          ),

          // ── Continue/Submit button ─────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
            color: _white,
            child: GestureDetector(
              onTap: _submitting ? null : _next,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 54,
                decoration: BoxDecoration(
                  color: _submitting
                      ? const Color(0xFFE5E7EB)
                      : _green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _submitting
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
                child: _submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _green.withValues(alpha: 0.7)),
                        ),
                      )
                    : Text(
                        _step < 2 ? 'Continue' : 'Create station',
                        style: _sg(15, FontWeight.w700,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Account ─────────────────────────────────────────────────────────
  Widget _stepAccount(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepHeader(
          icon: PhosphorIconsRegular.userCircle,
          title: 'Account',
          subtitle: 'Set up your operator login',
        ),
        const SizedBox(height: 20),
        if (widget.phoneE164 != null)
          _InfoBanner('Phone verified: ${widget.phoneE164}'),
        const SizedBox(height: 12),
        _field(_emailCtrl, 'Business email',
            icon: PhosphorIconsRegular.envelope,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(_passwordCtrl, 'Password',
            icon: PhosphorIconsRegular.lock, obscure: true),
        const SizedBox(height: 12),
        _field(_confirmCtrl, 'Confirm password',
            icon: PhosphorIconsRegular.lock, obscure: true),
        const SizedBox(height: 10),
        Text(
          'Password is stored for future email login; phone OTP remains your sign-in method.',
          style: _dm(12, FontWeight.w400, color: _slate, h: 1.5),
        ),
      ],
    );
  }

  // ── Step 2: Station info ────────────────────────────────────────────────────
  Widget _stepStation(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepHeader(
          icon: PhosphorIconsRegular.chargingStation,
          title: 'Station information',
          subtitle: 'Basic details about your charging hub',
        ),
        const SizedBox(height: 20),
        _field(_stationNameCtrl, 'Station name *',
            icon: PhosphorIconsRegular.chargingStation),
        const SizedBox(height: 12),
        _field(_cityCtrl, 'City / region *',
            icon: PhosphorIconsRegular.city),
        const SizedBox(height: 12),
        _field(_addressCtrl, 'Detailed address *',
            icon: PhosphorIconsRegular.mapPin, maxLines: 2),
        const SizedBox(height: 12),
        // Location picker
        GestureDetector(
          onTap: _pickLocation,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pickedLocation != null ? _green : _border,
                width: _pickedLocation != null ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.mapTrifold,
                  size: 18,
                  color: _pickedLocation != null ? _green : _slate,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _pickedLocation?.formattedAddress ??
                        'Pin exact location on map *',
                    style: _dm(14, FontWeight.w400,
                        color: _pickedLocation != null
                            ? _ink
                            : _slate),
                  ),
                ),
                const Icon(PhosphorIconsRegular.caretRight,
                    size: 16, color: _slate),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(_openCtrl, 'Opens',
                  icon: PhosphorIconsRegular.clockAfternoon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_closeCtrl, 'Closes',
                  icon: PhosphorIconsRegular.clockAfternoon),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(_managerCtrl, 'Manager / owner name *',
            icon: PhosphorIconsRegular.userCircle),
        const SizedBox(height: 12),
        _field(_nationalIdCtrl, 'National ID (optional)',
            icon: PhosphorIconsRegular.identificationCard),
        const SizedBox(height: 12),
        _field(_backupCtrl, 'Backup contact',
            icon: PhosphorIconsRegular.phone),
      ],
    );
  }

  // ── Step 3: Verification ────────────────────────────────────────────────────
  Widget _stepVerification(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepHeader(
          icon: PhosphorIconsRegular.shieldCheck,
          title: 'Verification',
          subtitle: 'Final details before submission',
        ),
        const SizedBox(height: 20),
        _InfoBanner(
            'After submission, your station will be reviewed before '
            'appearing on the map as a Chargix partner.'),
        const SizedBox(height: 16),
        _field(_logoUrlCtrl, 'Logo URL (optional)',
            icon: PhosphorIconsRegular.image),
        const SizedBox(height: 12),
        Text(
          'You can manage bookings and appear on the map as a Chargix '
          'partner (green marker) once approved.',
          style: _dm(13, FontWeight.w400, color: _slate, h: 1.5),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscure,
      style: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: _slate),
        prefixIcon: icon != null
            ? Icon(icon, size: 17, color: _slate)
            : null,
        filled: true,
        fillColor: _white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _green, width: 1.5)),
      ),
    );
  }
}

// ── Step header ───────────────────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _greenSurface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: _green.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(icon, size: 20, color: _greenDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.2)),
              Text(subtitle,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _slate)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  const _InfoBanner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _greenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _green.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(PhosphorIconsRegular.info, size: 14, color: _greenDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _greenDark,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}
