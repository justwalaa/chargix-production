import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  // Six individual controllers + focus nodes for the digit boxes.
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  String? _errorMessage;

  // Resend countdown (60 s)
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first digit on open.
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  // ── OTP helpers ───────────────────────────────────────────────────────────

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits filled.
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  // Handle paste: fill all boxes from index 0.
  void _onFieldTap(int index) {
    _controllers[index].selection = TextSelection.fromPosition(
      TextPosition(offset: _controllers[index].text.length),
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length < 6) return;
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    _unfocus();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      // ChargixApp auth listener + root navigator reset shows the dashboard.
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = _friendlyError(e);
      });
      _clearDigits();
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _focusNodes[0].requestFocus(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Verification failed. Please try again.';
      });
      _clearDigits();
    } finally {
      // Success path: root navigator is replaced; only reset on failure above.
      if (mounted && FirebaseAuth.instance.currentUser != null) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _clearDigits() {
    for (final c in _controllers) c.clear();
  }

  void _unfocus() {
    for (final f in _focusNodes) f.unfocus();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Incorrect code. Check the SMS and try again.';
      case 'session-expired':
        return 'Session expired. Please request a new code.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      default:
        return e.message ?? 'Verification failed. Please try again.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF080B14),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Color(0xFF5A7FA8), size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
        const Text(
          'Enter verification code',
          style: TextStyle(
            color: Color(0xFFEEF4FF),
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF5A7FA8),
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: masked,
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
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
          focusNode: _focusNodes[i],
          hasError: _errorMessage != null,
          onChanged: (v) => _onDigitChanged(i, v),
          onTap: () => _onFieldTap(i),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return ElevatedButton(
      onPressed: _isVerifying ? null : _verifyOtp,
      child: _isVerifying
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080B14)),
        ),
      )
          : const Text('Verify'),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D6A).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border:
        Border.all(color: const Color(0xFFFF4D6A).withAlpha(50), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFFF4D6A), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFF4D6A),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendRow() {
    final canResend = _resendSeconds <= 0 && !_isVerifying;
    return Center(
      child: _resendSeconds > 0
          ? Text(
        'Resend code in $_resendSeconds s',
        style: const TextStyle(
          color: Color(0xFF2E4060),
          fontSize: 13,
        ),
      )
          : TextButton(
        onPressed: canResend ? _onResend : null,
        child: const Text("Didn't receive it? Resend"),
      ),
    );
  }

  void _onResend() {
    // Pop back to LoginScreen — user re-enters phone and triggers reCAPTCHA.
    // This is the safest flow: reuses the same verifyPhoneNumber() path.
    Navigator.of(context).pop();
  }

  String _maskPhone(String e164) {
    if (e164.length < 5) return e164;
    final visible = e164.substring(e164.length - 3);
    final prefix = e164.substring(0, e164.length - 7);
    return '$prefix *** $visible';
  }
}

// ── Single digit input box ─────────────────────────────────────────────────

class _DigitBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        onTap: onTap,
        style: const TextStyle(
          color: Color(0xFFEEF4FF),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: controller.text.isNotEmpty
              ? const Color(0xFF00D4FF).withAlpha(15)
              : const Color(0xFF0D1526),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFFF4D6A)
                  : controller.text.isNotEmpty
                  ? const Color(0xFF00D4FF).withAlpha(80)
                  : const Color(0xFF1E3A5F),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFFF4D6A)
                  : const Color(0xFF00D4FF),
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
