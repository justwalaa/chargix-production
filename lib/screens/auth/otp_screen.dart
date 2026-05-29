// lib/screens/auth/otp_screen.dart
//
// OTP verification for driver phone authentication.
//
// NAVIGATION FIX:
//   Old behaviour: signInWithCredential succeeds, but the OtpScreen and
//   DriverLoginScreen remained on the navigator stack. The user had to press
//   Android Back to reveal MainNavigation.
//
//   New behaviour: after signInWithCredential, we call
//     AppNavigator.pushReplaceAll(await SessionGate.resolveHome())
//   This clears the ENTIRE auth stack (OtpScreen + DriverLoginScreen +
//   LoginScreen) and routes directly to the correct home (MainNavigation for
//   drivers, StationMainNavigation for owners, etc.) without any back-press.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/routing/session_gate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneE164;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneE164,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  String? _errorMessage;

  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (--_resendSeconds <= 0) t.cancel();
      });
    });
  }

  // ── OTP logic ──────────────────────────────────────────────────────────────

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int i, String value) {
    if (value.length == 1 && i < 5) _focusNodes[i + 1].requestFocus();
    if (value.isEmpty   && i > 0) _focusNodes[i - 1].requestFocus();
    if (_code.length == 6) _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    if (_code.length < 6 || _isVerifying) return;

    setState(() {
      _isVerifying   = true;
      _errorMessage  = null;
    });
    for (final f in _focusNodes) {
      f.unfocus();
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // ── THE FIX ──────────────────────────────────────────────────────────
      // Resolve the correct home (role-aware) and replace the ENTIRE
      // navigation stack. No auth screen remains — no back-press needed.
      final home = await SessionGate.resolveHome();
      AppNavigator.pushReplaceAll(home);
      // ─────────────────────────────────────────────────────────────────────

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying  = false;
        _errorMessage = _friendlyError(e);
      });
      _clearDigits();
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _focusNodes[0].requestFocus(),
      );
    }
  }

  void _clearDigits() {
    for (final c in _controllers) {
      c.clear();
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code': return 'Wrong code — check your SMS and try again.';
      case 'session-expired':           return 'Code expired. Go back and request a new one.';
      case 'too-many-requests':         return 'Too many attempts. Please wait.';
      default: return e.message ?? 'Verification failed. Try again.';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg1,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 48),
                _buildDigitRow(),
                const SizedBox(height: 32),
                _buildVerifyButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildError(),
                ],
                const SizedBox(height: 32),
                _buildResendRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final masked = _maskPhone(widget.phoneE164);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verify your number', style: AppTextStyles.h1),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMd,
            children: [
              const TextSpan(text: 'Enter the 6-digit code sent to '),
              TextSpan(
                text: masked,
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
            (i) => _DigitBox(
          controller: _controllers[i],
          focusNode:  _focusNodes[i],
          hasError:   _errorMessage != null,
          onChanged:  (v) => _onDigitChanged(i, v),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: !_isVerifying ? AppColors.primaryGradient : null,
        color: _isVerifying ? AppColors.bg4 : null,
        boxShadow: !_isVerifying ? [
          BoxShadow(
            color: AppColors.cyanGlow(0.3),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isVerifying ? null : _verifyOtp,
          child: Center(
            child: _isVerifying
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            )
                : Text(
              'Verify code',
              style: AppTextStyles.button
                  .copyWith(color: AppColors.bg1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withAlpha(60), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendRow() {
    return Center(
      child: _resendSeconds > 0
          ? Text(
        'Resend in ${_resendSeconds}s',
        style: AppTextStyles.labelMd
            .copyWith(color: AppColors.textMuted),
      )
          : TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Didn't receive it? Go back to resend"),
      ),
    );
  }

  String _maskPhone(String e164) {
    if (e164.length < 5) return e164;
    final prefix  = e164.substring(0, e164.length - 7);
    final visible = e164.substring(e164.length - 3);
    return '$prefix *** $visible';
  }
}

// ── Single digit box ──────────────────────────────────────────────────────

class _DigitBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 58,
      child: TextField(
        controller: controller,
        focusNode:  focusNode,
        keyboardType: TextInputType.number,
        textAlign:  TextAlign.center,
        maxLength:  1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged:  onChanged,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled:    true,
          fillColor: controller.text.isNotEmpty
              ? AppColors.cyan.withAlpha(18)
              : AppColors.bg4,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError
                  ? AppColors.red
                  : controller.text.isNotEmpty
                  ? AppColors.cyan.withAlpha(90)
                  : AppColors.border2,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? AppColors.red : AppColors.cyan,
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}