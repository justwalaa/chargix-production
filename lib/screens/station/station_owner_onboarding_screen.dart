import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/routing/session_gate.dart';
import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import '../../models/operating_hours_model.dart';
import '../../models/station_registration_draft.dart';
import '../../theme/app_gradients.dart';
import '../../theme/tokens/tokens.dart';

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

class _StationOwnerOnboardingScreenState extends State<StationOwnerOnboardingScreen> {
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

  double _lat = 31.9539;
  double _lng = 35.9106;

  @override
  void dispose() {
    _page.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _stationNameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    _managerCtrl.dispose();
    _nationalIdCtrl.dispose();
    _backupCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location captured')),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read GPS location')),
        );
      }
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _submitting = true);
    final draft = StationRegistrationDraft(
      stationName: _stationNameCtrl.text.trim(),
      contactEmail: _emailCtrl.text.trim(),
      contactPhone: widget.phoneE164 ?? '',
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: _lat,
      longitude: _lng,
      operatingHours: OperatingHoursModel(
        openTime: _openCtrl.text.trim(),
        closeTime: _closeCtrl.text.trim(),
      ),
      managerName: _managerCtrl.text.trim(),
      managerNationalId: _nationalIdCtrl.text.trim().isEmpty
          ? null
          : _nationalIdCtrl.text.trim(),
      backupContactPhone:
          _backupCtrl.text.trim().isEmpty ? null : _backupCtrl.text.trim(),
      logoUrl: _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
    );

    final result = await ChargixData.stationOwner.submitPartnerRegistration(
      ownerUserId: widget.ownerUserId,
      draft: draft,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (result is DataSuccess<String>) {
      final home = await SessionGate.resolveHome();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => home),
        (_) => false,
      );
    } else if (result is DataError<String>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: ${result.errorOrNull}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register station (${_step + 1}/3)'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 3),
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            child: FilledButton(
              onPressed: _submitting ? null : _next,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_step < 2 ? 'Continue' : 'Submit for approval'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepAccount(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenGutter),
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Phone verified: ${widget.phoneE164 ?? '—'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Business email'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _confirmCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm password'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Password is stored for future email login; phone OTP remains your sign-in method.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _stepStation(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenGutter),
      children: [
        Text(
          'Station information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _stationNameCtrl,
          decoration: const InputDecoration(labelText: 'Station name *'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _cityCtrl,
          decoration: const InputDecoration(labelText: 'City / region *'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Detailed address *'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _useMyLocation,
          icon: const Icon(Icons.my_location_rounded),
          label: Text('Use GPS ($_lat, $_lng)'),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _openCtrl,
                decoration: const InputDecoration(labelText: 'Opens'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _closeCtrl,
                decoration: const InputDecoration(labelText: 'Closes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _managerCtrl,
          decoration: const InputDecoration(labelText: 'Manager / owner name *'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _nationalIdCtrl,
          decoration: const InputDecoration(labelText: 'National ID (optional)'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _backupCtrl,
          decoration: const InputDecoration(labelText: 'Backup contact'),
        ),
      ],
    );
  }

  Widget _stepVerification(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenGutter),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
          ),
          child: const Text(
            'Verification',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _logoUrlCtrl,
          decoration: const InputDecoration(
            labelText: 'Logo URL (optional)',
            hintText: 'https://… or upload later in dashboard',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'After submission, your station stays hidden until Chargix approves it. '
          'You will then appear as a partner on the map with booking enabled.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
