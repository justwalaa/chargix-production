import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/chargix_data.dart';
import '../../models/enums/user_role.dart';
import '../../models/station_model.dart';
import '../../models/user_model.dart';
import '../../navigation/main_navigation.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/onboarding/vehicle_setup_screen.dart';
import '../../screens/station/station_main_navigation.dart';
import '../../screens/station/station_owner_onboarding_screen.dart';
import '../result/data_state.dart';

// Design tokens (reused from app theme)
const _green     = Color(0xFF22C55E);
const _greenDark = Color(0xFF16A34A);
const _greenSf   = Color(0xFFDCFCE7);
const _canvas    = Color(0xFFF8F9FA);
const _white     = Color(0xFFFFFFFF);
const _ink       = Color(0xFF101828);
const _slate     = Color(0xFF6B7280);
const _border    = Color(0xFFE5E7EB);

String _sha256(String input) =>
    sha256.convert(utf8.encode(input)).toString();

/// Resolves the correct home shell after splash / login from Firestore profile.
abstract final class SessionGate {
  static const Duration _bootstrapTimeout = Duration(seconds: 20);

  static const int _maxRetries = 6;
  static const Duration _retryBase = Duration(milliseconds: 600);

  static Future<Widget> resolveHome() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      final uid = authUser?.uid;
      if (uid == null) {
        return const LoginScreen();
      }

      var profile = await _loadProfile(uid);
      profile ??= await _bootstrapProfile(authUser!);
      if (profile == null) {
        debugPrint(
          'Chargix SessionGate: no profile for $uid — returning login.',
        );
        return const LoginScreen();
      }

      if (await _isStationOperator(uid, profile)) {
        return await _resolveStationHome(uid: uid, profile: profile);
      }

      // First-time driver: collect name/password, then onboarding → home.
      // hasCompletedRegistration == false  → brand-new user (explicit flag).
      // hasCompletedRegistration == null   → legacy user (field absent) → treat as done.
      final onboardingDone = await OnboardingScreen.isDone();
      final isNew = profile.hasCompletedRegistration == false;
      if (!onboardingDone || isNew) {
        debugPrint('Chargix SessionGate: driver → first-run flow ($uid)');
        return _FirstRunDriverFlow(
          uid: uid,
          phoneE164: profile.phoneE164,
          needsName: isNew,
          skipOnboarding: onboardingDone,
        );
      }

      debugPrint('Chargix SessionGate: driver → MainNavigation ($uid)');
      return const MainNavigation();
    } on TimeoutException catch (e, st) {
      debugPrint('Chargix SessionGate: bootstrap timed out: $e\n$st');
      return const LoginScreen();
    } catch (e, st) {
      debugPrint('Chargix SessionGate: resolveHome failed: $e\n$st');
      return const LoginScreen();
    }
  }

  /// Station operators must never land on the driver shell.
  static Future<bool> _isStationOperator(String uid, UserModel profile) async {
    if (profile.role.isStation) {
      return true;
    }
    final stationId = profile.stationId;
    if (stationId != null && stationId.isNotEmpty) {
      return true;
    }

    final owned = await ChargixData.stations.getStation(uid);
    final station = owned.dataOrNull;
    if (station != null) {
      final ownerId = station.ownerUserId;
      if (ownerId == uid || station.id == uid) {
        debugPrint(
          'Chargix SessionGate: station doc detected for $uid '
          '(role=${profile.role.value})',
        );
        return true;
      }
    }
    return false;
  }

  static Future<UserModel?> _loadProfile(String uid) async {
    final state =
        await ChargixData.users.getUser(uid).timeout(_bootstrapTimeout);
    if (state is DataSuccess<UserModel>) {
      return state.data;
    }
    if (state is DataError<UserModel>) {
      debugPrint('Chargix SessionGate: getUser error: ${state.error}');
    }
    return null;
  }

  static Future<UserModel?> _bootstrapProfile(User authUser) async {
    final uid = authUser.uid;
    final phone = (authUser.phoneNumber ?? '').trim();
    final email = (authUser.email ?? '').trim();

    if (phone.isEmpty && email.isEmpty) {
      return null;
    }

    if (phone.isEmpty && email.isNotEmpty) {
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        await Future<void>.delayed(_retryBase * attempt);
        final retry = await _loadProfile(uid);
        if (retry != null) return retry;
      }
      return null;
    }

    if (phone.isEmpty) return null;

    // Do not create a driver profile if this uid already owns a station.
    final stationState = await ChargixData.stations.getStation(uid);
    if (stationState.dataOrNull != null) {
      debugPrint(
        'Chargix SessionGate: station doc exists for $uid — skip driver bootstrap',
      );
      return _loadProfile(uid);
    }

    final result = await ChargixData.users
        .ensureUserAfterSignIn(
          uid: uid,
          phoneE164: phone,
          role: UserRole.user,
        )
        .timeout(_bootstrapTimeout);

    if (result is DataSuccess<UserModel>) {
      return result.data;
    }
    return null;
  }

  static Future<Widget> _resolveStationHome({
    required String uid,
    required UserModel profile,
  }) async {
    final stationId = profile.stationId ?? uid;

    StationModel? station;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_retryBase * attempt);
      }
      final state = await ChargixData.stations
          .getStation(stationId)
          .timeout(_bootstrapTimeout);
      station = state.dataOrNull;
      if (station != null) break;
    }

    if (station == null) {
      return StationOwnerOnboardingScreen(
        ownerUserId: uid,
        phoneE164: profile.phoneE164,
      );
    }

    debugPrint(
      'Chargix SessionGate: station operator → dashboard ($stationId)',
    );
    return StationMainNavigation(stationId: stationId);
  }
}

// ── First-run driver flow ─────────────────────────────────────────────────────
/// Shown once for new drivers: NameCollection? → Onboarding? → VehicleSetup → Home.
class _FirstRunDriverFlow extends StatefulWidget {
  const _FirstRunDriverFlow({
    required this.uid,
    required this.phoneE164,
    required this.needsName,
    required this.skipOnboarding,
  });

  final String uid;
  final String phoneE164;
  final bool needsName;
  final bool skipOnboarding;

  @override
  State<_FirstRunDriverFlow> createState() => _FirstRunDriverFlowState();
}

enum _Phase { nameCollection, onboarding, vehicleSetup }

class _FirstRunDriverFlowState extends State<_FirstRunDriverFlow> {
  late _Phase _phase;

  @override
  void initState() {
    super.initState();
    _phase = widget.needsName
        ? _Phase.nameCollection
        : widget.skipOnboarding
            ? _Phase.vehicleSetup
            : _Phase.onboarding;
  }

  void _onNameDone() {
    if (!mounted) return;
    setState(() => _phase = widget.skipOnboarding
        ? _Phase.vehicleSetup
        : _Phase.onboarding);
  }

  void _onOnboardingDone() {
    OnboardingScreen.markDone(() {
      if (mounted) setState(() => _phase = _Phase.vehicleSetup);
    });
  }

  void _onVehicleSetupDone() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.nameCollection => _NameCollectionView(
          uid: widget.uid,
          phoneE164: widget.phoneE164,
          onComplete: _onNameDone,
        ),
      _Phase.onboarding =>
        OnboardingScreen(onComplete: _onOnboardingDone),
      _Phase.vehicleSetup =>
        VehicleSetupScreen(onComplete: _onVehicleSetupDone),
    };
  }
}

// ── Name + Password collection (shown once for new drivers) ───────────────────
class _NameCollectionView extends StatefulWidget {
  const _NameCollectionView({
    required this.uid,
    required this.phoneE164,
    required this.onComplete,
  });

  final String uid;
  final String phoneE164;
  final VoidCallback onComplete;

  @override
  State<_NameCollectionView> createState() => _NameCollectionViewState();
}

class _NameCollectionViewState extends State<_NameCollectionView> {
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      // Update Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      // Get existing profile to preserve all fields
      final state = await ChargixData.users.getUser(widget.uid);
      final existing = state.dataOrNull;

      if (existing != null) {
        await ChargixData.users.updateProfile(
          existing.copyWith(
            displayName: name,
            passwordHash: _sha256(pass),
            hasCompletedRegistration: true,
          ),
        );
      }
    } catch (_) {
      // Non-blocking — proceed even if update fails
    }

    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _canvas,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, topPad + 48, 28, bottomPad + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _greenSf,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: _greenDark, size: 26),
              ),
              const SizedBox(height: 24),
              Text('Set up your profile',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: _ink, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text('This is shown once. You can update it later in your profile.',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w400,
                      color: _slate, height: 1.5)),
              const SizedBox(height: 36),

              _Field(
                controller: _nameCtrl,
                label: 'Full name',
                hint: 'e.g. Sara Al-Ahmad',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _passCtrl,
                label: 'Password',
                hint: 'Min 8 characters',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _slate, size: 18,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _confirmCtrl,
                label: 'Confirm password',
                hint: 'Repeat password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _slate, size: 18,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: const Color(0xFFDC2626))),
                ),
              ],

              const SizedBox(height: 28),
              GestureDetector(
                onTap: _saving ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 56,
                  decoration: BoxDecoration(
                    color: _saving ? const Color(0xFFE5E7EB) : _green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _saving ? [] : [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.35),
                        blurRadius: 20, spreadRadius: -4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _green.withValues(alpha: 0.7)),
                          ),
                        )
                      : Text('Continue',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: _white, letterSpacing: 0.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.dmSans(fontSize: 15, color: _ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: _slate),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _white,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: _slate),
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _slate),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
