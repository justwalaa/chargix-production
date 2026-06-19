import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import 'reset_password_screen.dart';
import 'station_register_screen.dart';

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

class StationLoginScreen extends StatefulWidget {
  const StationLoginScreen({super.key});

  @override
  State<StationLoginScreen> createState() => _StationLoginScreenState();
}

class _StationLoginScreenState extends State<StationLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _signingInGoogle = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) setState(() => _isLoading = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _friendlyError(e); });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign in failed. Please try again.';
      });
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-email':
        return 'Invalid email address format.';
      default:
        return e.message ?? 'Sign in failed. Please try again.';
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
          padding: EdgeInsets.fromLTRB(28, topPad + 16, 28, bottomPad + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(PhosphorIconsRegular.arrowLeft,
                      color: _ink, size: 18),
                ),
              ),

              const SizedBox(height: 32),

              // Icon badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _greenSurface,
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
                child: const Icon(PhosphorIconsFill.chargingStation,
                    color: _greenDark, size: 26),
              )
                  .animate()
                  .fadeIn(duration: 380.ms)
                  .scale(begin: const Offset(0.7, 0.7),
                      duration: 380.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              Text('Station owner portal',
                      style: _sg(28, FontWeight.w800, ls: -0.5))
                  .animate()
                  .fadeIn(delay: 60.ms, duration: 360.ms)
                  .slideY(begin: 0.08, end: 0, delay: 60.ms,
                      duration: 360.ms, curve: Curves.easeOut),

              const SizedBox(height: 8),

              Text('Sign in to manage your charging station.',
                      style: _dm(15, FontWeight.w400,
                          color: _slate, h: 1.5))
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 340.ms),

              const SizedBox(height: 36),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _InputField(
                      controller: _emailController,
                      label: 'Email address',
                      icon: PhosphorIconsRegular.envelope,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(delay: 140.ms, duration: 320.ms),

                    const SizedBox(height: 12),

                    _InputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: PhosphorIconsRegular.lock,
                      obscureText: _obscurePassword,
                      onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter your password';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 320.ms),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ResetPasswordScreen(
                          initialEmail:
                              _emailController.text.trim()),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('Forgot password?',
                        style:
                            _dm(13, FontWeight.w500, color: _slate)),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Sign in button
              _SignInButton(isLoading: _isLoading, onTap: _signIn)
                  .animate()
                  .fadeIn(delay: 220.ms, duration: 320.ms)
                  .slideY(begin: 0.08, end: 0, delay: 220.ms,
                      duration: 320.ms, curve: Curves.easeOut),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _ErrorBanner(message: _errorMessage!),
              ],

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: _border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or',
                        style: _dm(12, FontWeight.w400, color: _slate)),
                  ),
                  const Expanded(child: Divider(color: _border)),
                ],
              ),

              // TODO: re-enable after thesis defense
              if (false) ...[
                const SizedBox(height: 16),
                // Google Sign-In
                GestureDetector(
                  onTap: _signingInGoogle ? null : _signInWithGoogle,
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
                    child: _signingInGoogle
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
                              Text('G',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF4285F4))),
                              const SizedBox(width: 10),
                              Text('Continue with Google',
                                  style: _dm(15, FontWeight.w600, color: _ink)),
                            ],
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 300.ms),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider(color: _border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or',
                          style: _dm(12, FontWeight.w400, color: _slate)),
                    ),
                    const Expanded(child: Divider(color: _border)),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              Center(
                child: Column(
                  children: [
                    Text("Don't have a station account?",
                        style: _dm(13, FontWeight.w400, color: _slate)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StationRegisterScreen(),
                        ),
                      ),
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
                            const Icon(PhosphorIconsRegular.plus,
                                size: 14, color: _slate),
                            const SizedBox(width: 7),
                            Text('Register your station',
                                style: _dm(13, FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 280.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared input field ────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onToggleObscure,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autocorrect: false,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: _slate),
        prefixIcon: Icon(icon, size: 18, color: _slate),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? PhosphorIconsRegular.eye
                      : PhosphorIconsRegular.eyeSlash,
                  size: 18,
                  color: _slate,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// ── Sign-in button ────────────────────────────────────────────────────────────
class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.isLoading, required this.onTap});
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
          color: isLoading ? const Color(0xFFE5E7EB) : _green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
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
        child: isLoading
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
                  Text('Sign in',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2)),
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
