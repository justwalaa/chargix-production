
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'otp_screen.dart';
import 'station_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Country code — default Jordan (+962). Extend with a picker if needed.
  String _countryCode = '+962';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ── Send OTP ──────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ FIX: Capture navigator BEFORE the async gap caused by verifyPhoneNumber.
    // After reCAPTCHA opens a WebView, the original BuildContext may be
    // deactivated. The captured NavigatorState reference stays valid.
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phoneE164 =
        '$_countryCode${_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 120),

      // Auto-verified (Android instant verification — rare).
      // SessionGate handles post-auth routing via the StreamSubscription
      // in app.dart — no manual navigation needed here.
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        // ✅ FIX: mounted check — this fires after async gap.
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = _friendlyError(e);
        });
      },

      // ✅ FIX: Use pre-captured navigator, not context.
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneE164: phoneE164,
            ),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        // Silent — the OTP screen timer handles expiry UI.
      },
    );
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format. Include country code.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 48),
                _buildForm(),
                const SizedBox(height: 32),
                _buildSendButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildError(),
                ],
                const SizedBox(height: 40),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildStationOwnerLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Electric bolt icon as brand mark
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00D4FF).withAlpha(60),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Color(0xFF00D4FF),
            size: 28,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome back',
          style: TextStyle(
            color: Color(0xFFEEF4FF),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your phone number to continue charging.',
          style: TextStyle(
            color: Color(0xFF5A7FA8),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone number',
            style: TextStyle(
              color: Color(0xFF8AAAC8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Country code selector
              GestureDetector(
                onTap: _showCountryCodePicker,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1526),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1E3A5F),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _countryCode,
                        style: const TextStyle(
                          color: Color(0xFFEEF4FF),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF2E4060),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  style: const TextStyle(
                    color: Color(0xFFEEF4FF),
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                  decoration: const InputDecoration(
                    hintText: '7X XXX XXXX',
                    hintStyle: TextStyle(color: Color(0xFF2E4060), letterSpacing: 1),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your phone number';
                    }
                    if (v.trim().length < 7) {
                      return 'Phone number too short';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _sendOtp,
      child: _isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080B14)),
        ),
      )
          : const Text('Send verification code'),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D6A).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF4D6A).withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF4D6A), size: 16),
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: const Color(0xFF1A2840), height: 1),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(color: Color(0xFF2E4060), fontSize: 12),
          ),
        ),
        Expanded(
          child: Divider(color: const Color(0xFF1A2840), height: 1),
        ),
      ],
    );
  }

  Widget _buildStationOwnerLink() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Own a charging station?',
            style: TextStyle(color: Color(0xFF5A7FA8), fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StationLoginScreen(),
                ),
              );
            },
            child: const Text('Station owner portal →'),
          ),
        ],
      ),
    );
  }

  void _showCountryCodePicker() {
    // Simple picker — extend with a full country list package if needed.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A0F1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        const codes = [
          ('+962', 'Jordan 🇯🇴'),
          ('+966', 'Saudi Arabia 🇸🇦'),
          ('+971', 'UAE 🇦🇪'),
          ('+970', 'Palestine 🇵🇸'),
          ('+20', 'Egypt 🇪🇬'),
          ('+1', 'USA / Canada 🇺🇸'),
          ('+44', 'UK 🇬🇧'),
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2E4060),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ...codes.map((c) => ListTile(
              title: Text(
                '${c.$2}  ${c.$1}',
                style: const TextStyle(
                  color: Color(0xFFEEF4FF),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                setState(() => _countryCode = c.$1);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}