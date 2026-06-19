import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import 'otp_screen.dart';
import 'station_login_screen.dart';

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
    {Color color = _ink, double ls = 0, double? height}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color,
        letterSpacing: ls, height: height);

TextStyle _dm(double size, FontWeight w,
    {Color color = _ink, double? height}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: height);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _signingInGoogle = false;
  bool _isSignUp = false;
  String? _errorMessage;
  String _countryCode = '+962';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _signingInGoogle = true; _errorMessage = null; });
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _signingInGoogle = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = uc.user?.uid;
      if (uid == null) throw Exception('sign-in returned no uid');
      await ChargixData.users.ensureUserAfterSignIn(
        uid: uid,
        phoneE164: '',
        email: googleUser.email,
        authProvider: 'google',
      );
      // Auth state listener in the app shell handles navigation
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _signingInGoogle = false;
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    setState(() { _isLoading = true; _errorMessage = null; });

    final rawDigits =
        _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final phoneE164 = '$_countryCode$rawDigits';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() { _isLoading = false; _errorMessage = _friendlyError(e); });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        navigator.push(MaterialPageRoute<void>(
          builder: (_) => OtpScreen(
            verificationId: verificationId,
            phoneE164: phoneE164,
          ),
        ));
      },
      codeAutoRetrievalTimeout: (_) {},
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
              // ── Logo mark ──────────────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _greenSf,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _green.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(PhosphorIconsFill.lightning,
                    color: _greenDark, size: 26),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.7, 0.7), duration: 400.ms,
                      curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              // ── Tab switcher ───────────────────────────────────────────
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _isSignUp = false; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? _white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isSignUp
                                ? [BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1))]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text('Log in',
                              style: _dm(14, !_isSignUp
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                                  color: !_isSignUp ? _ink : _slate)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _isSignUp = true; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _isSignUp ? _white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isSignUp
                                ? [BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1))]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text('Sign up',
                              style: _dm(14, _isSignUp
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                                  color: _isSignUp ? _ink : _slate)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 60.ms, duration: 340.ms),

              const SizedBox(height: 28),

              // ── Heading ────────────────────────────────────────────────
              Text(_isSignUp ? 'Create account' : 'Welcome back',
                      style: _sg(30, FontWeight.w800, ls: -0.5))
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 380.ms)
                  .slideY(begin: 0.1, end: 0, delay: 80.ms, duration: 380.ms,
                      curve: Curves.easeOut),

              const SizedBox(height: 8),

              Text(_isSignUp
                      ? 'Enter your phone number to get started.'
                      : 'Enter your phone number to continue charging.',
                      style: _dm(15, FontWeight.w400,
                          color: _slate, height: 1.5))
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 360.ms),

              const SizedBox(height: 44),

              // ── Form ───────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone number',
                            style: _dm(13, FontWeight.w600, color: _slate))
                        .animate()
                        .fadeIn(delay: 160.ms, duration: 320.ms),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Country code picker
                        GestureDetector(
                          onTap: _showCountryCodePicker,
                          child: Container(
                            height: 54,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_countryCode,
                                    style: _dm(15, FontWeight.w500)),
                                const SizedBox(width: 4),
                                const Icon(
                                    PhosphorIconsRegular.caretDown,
                                    color: _slate,
                                    size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Phone input
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                            ],
                            style: _dm(16, FontWeight.w500,
                                height: 1.2),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _white,
                              hintText: '7X XXX XXXX',
                              hintStyle:
                                  _dm(15, FontWeight.w400, color: const Color(0xFFD1D5DB)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: _border, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: _border, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: _green, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFDC2626), width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFDC2626), width: 1.5),
                              ),
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
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 340.ms)
                        .slideY(begin: 0.08, end: 0, delay: 200.ms,
                            duration: 340.ms, curve: Curves.easeOut),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Send button ────────────────────────────────────────────
              _SendButton(isLoading: _isLoading, onTap: _sendOtp)
                  .animate()
                  .fadeIn(delay: 260.ms, duration: 340.ms)
                  .slideY(begin: 0.08, end: 0, delay: 260.ms, duration: 340.ms,
                      curve: Curves.easeOut),

              // ── Error ──────────────────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _errorMessage!),
              ],

              const SizedBox(height: 28),

              // ── Divider ────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: _border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or',
                        style: _dm(12, FontWeight.w400, color: _slate)),
                  ),
                  const Expanded(child: Divider(color: _border)),
                ],
              )
                  .animate()
                  .fadeIn(delay: 320.ms, duration: 300.ms),

              // TODO: re-enable after thesis defense
              if (false) ...[
                const SizedBox(height: 16),
                // ── Google Sign-In ───────────────────────────────────────
                _GoogleButton(
                  isLoading: _signingInGoogle,
                  onTap: _signInWithGoogle,
                )
                    .animate()
                    .fadeIn(delay: 360.ms, duration: 300.ms),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: _border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or',
                          style: _dm(12, FontWeight.w400, color: _slate)),
                    ),
                    const Expanded(child: Divider(color: _border)),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // ── Station owner link ─────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text('Own a charging station?',
                        style: _dm(13, FontWeight.w400, color: _slate)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const StationLoginScreen(),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsRegular.buildingOffice,
                                size: 16, color: _slate),
                            const SizedBox(width: 8),
                            Text('Station owner portal',
                                style: _dm(13, FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 360.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Select country code',
                  style: _sg(15, FontWeight.w700)),
            ),
            ...codes.map((c) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: Text(c.$1,
                      style: _sg(15, FontWeight.w700, color: _green)),
                  title: Text(c.$2, style: _dm(14, FontWeight.w400)),
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

// ── Send button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isLoading, required this.onTap});
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        decoration: BoxDecoration(
          color: isLoading
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF22C55E)),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Send verification code',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      )),
                  const SizedBox(width: 8),
                  const Icon(PhosphorIconsRegular.arrowRight,
                      color: Colors.white, size: 18),
                ],
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
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFFDC2626),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.1, end: 0,
        duration: 260.ms, curve: Curves.easeOut);
  }
}

// ── Google Sign-In button ─────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onTap});
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _slate.withValues(alpha: 0.7)),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Text(
                      'G',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Continue with Google',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      )),
                ],
              ),
      ),
    );
  }
}
