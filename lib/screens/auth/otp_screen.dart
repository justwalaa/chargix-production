// lib/screens/auth/otp_screen.dart
//
// OTP verification — light/green premium design.
// After signInWithCredential: clears the entire auth stack and routes to the
// correct home via SessionGate.resolveHome() + AppNavigator.pushReplaceAll.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/routing/session_gate.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _green     = Color(0xFF22C55E);
const _greenDark = Color(0xFF16A34A);
const _greenSf   = Color(0xFFDCFCE7);
const _canvas    = Color(0xFFF8F9FA);
const _white     = Color(0xFFFFFFFF);
const _ink       = Color(0xFF101828);
const _slate     = Color(0xFF6B7280);
const _border    = Color(0xFFE5E7EB);

TextStyle _sg(double size, FontWeight w,
    {Color color = _ink, double ls = 0}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

TextStyle _dm(double size, FontWeight w,
    {Color color = _ink, double? height}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: height);

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
        (_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes)  { f.dispose(); }
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { if (--_resendSeconds <= 0) t.cancel(); });
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int i, String value) {
    if (value.length == 1 && i < 5) _focusNodes[i + 1].requestFocus();
    if (value.isEmpty   && i > 0)   _focusNodes[i - 1].requestFocus();
    if (_code.length == 6) _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    if (_code.length < 6 || _isVerifying) return;
    setState(() { _isVerifying = true; _errorMessage = null; });
    for (final f in _focusNodes) { f.unfocus(); }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final home = await SessionGate.resolveHome();
      AppNavigator.pushReplaceAll(home);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() { _isVerifying = false; _errorMessage = _friendlyError(e); });
      _clearDigits();
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusNodes[0].requestFocus());
    }
  }

  void _clearDigits() {
    for (final c in _controllers) { c.clear(); }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Wrong code — check your SMS and try again.';
      case 'session-expired':
        return 'Code expired. Go back and request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait.';
      default:
        return e.message ?? 'Verification failed. Try again.';
    }
  }

  String _maskPhone(String e164) {
    if (e164.length < 5) return e164;
    final prefix  = e164.substring(0, e164.length - 7);
    final visible = e164.substring(e164.length - 3);
    return '$prefix *** $visible';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _canvas,
        body: Column(
          children: [
            // ── Back bar ───────────────────────────────────────────────
            SizedBox(
              height: topPad + 56,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 4),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                          PhosphorIconsRegular.arrowLeft,
                          color: _ink, size: 20),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(28, 32, 28, bottomPad + 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: 380.ms)
                        .slideY(begin: 0.1, end: 0, duration: 380.ms,
                            curve: Curves.easeOut),

                    const SizedBox(height: 48),

                    // ── Digit row ────────────────────────────────────────
                    _buildDigitRow()
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 360.ms)
                        .slideY(begin: 0.1, end: 0, delay: 100.ms,
                            duration: 360.ms, curve: Curves.easeOut),

                    const SizedBox(height: 36),

                    // ── Verify button ────────────────────────────────────
                    _VerifyButton(
                      isVerifying: _isVerifying,
                      onTap: _verifyOtp,
                    )
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 340.ms)
                        .slideY(begin: 0.08, end: 0, delay: 180.ms,
                            duration: 340.ms, curve: Curves.easeOut),

                    // ── Error ────────────────────────────────────────────
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _errorMessage!),
                    ],

                    const SizedBox(height: 36),

                    // ── Resend row ───────────────────────────────────────
                    _buildResendRow()
                        .animate()
                        .fadeIn(delay: 240.ms, duration: 320.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final masked = _maskPhone(widget.phoneE164);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _greenSf,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _green.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Icon(PhosphorIconsRegular.deviceMobile,
              color: _greenDark, size: 24),
        ),
        const SizedBox(height: 24),
        Text('Verify your number', style: _sg(28, FontWeight.w800, ls: -0.4)),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: _dm(15, FontWeight.w400, color: _slate, height: 1.5),
            children: [
              const TextSpan(text: 'Enter the 6-digit code sent to '),
              TextSpan(
                text: masked,
                style: _dm(15, FontWeight.w600, color: _ink),
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
        ),
      ),
    );
  }

  Widget _buildResendRow() {
    return Center(
      child: _resendSeconds > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsRegular.clockCountdown,
                    size: 14, color: _slate),
                const SizedBox(width: 6),
                Text(
                  'Resend in ${_resendSeconds}s',
                  style: _dm(13, FontWeight.w500, color: _slate),
                ),
              ],
            )
          : GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Text(
                    "Didn't receive it? Go back to resend",
                    style: _dm(13, FontWeight.w600, color: _green)),
              ),
            ),
    );
  }
}

// ── Verify button ─────────────────────────────────────────────────────────────

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.isVerifying, required this.onTap});
  final bool isVerifying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isVerifying ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        decoration: BoxDecoration(
          color: isVerifying ? const Color(0xFFE5E7EB) : _green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isVerifying
              ? []
              : [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isVerifying
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _green.withValues(alpha: 0.7)),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Verify code',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      )),
                  const SizedBox(width: 8),
                  const Icon(PhosphorIconsRegular.shieldCheck,
                      color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }
}

// ── Single digit box ──────────────────────────────────────────────────────────

class _DigitBox extends StatefulWidget {
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
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled   = widget.controller.text.isNotEmpty;
    final hasError = widget.hasError;

    Color borderColor;
    Color bgColor;

    if (hasError) {
      borderColor = const Color(0xFFDC2626);
      bgColor     = const Color(0xFFFEE2E2);
    } else if (filled) {
      borderColor = _green;
      bgColor     = _greenSf;
    } else if (_isFocused) {
      borderColor = _green;
      bgColor     = _white;
    } else {
      borderColor = _border;
      bgColor     = _white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: _isFocused || filled ? 1.5 : 1.0,
        ),
        boxShadow: (_isFocused && !hasError)
            ? [
                BoxShadow(
                  color: _green.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode:  widget.focusNode,
        keyboardType: TextInputType.number,
        textAlign:  TextAlign.center,
        maxLength:  1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.onChanged,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: hasError ? const Color(0xFFDC2626) : _ink,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.warningCircle,
              color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFDC2626),
                    height: 1.4)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(
        begin: -0.1, end: 0, duration: 240.ms, curve: Curves.easeOut);
  }
}
