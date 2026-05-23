import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/routing/session_gate.dart';
import '../../models/enums/user_role.dart';
import '../../services/auth_service.dart';
import '../../theme/app_gradients.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/auth/jordan_phone_field.dart';
import '../../widgets/chargix/chargix_brand_lockup.dart';
import 'otp_screen.dart';

/// Phone entry for Jordan (+962) numbers only; continues to OTP or main if auto-verified.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();

  bool _submitting = false;
  String? _fieldError;
  UserRole _accountType = UserRole.user;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (_fieldError != null) {
        setState(() => _fieldError = null);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String? _validateNational(String? value) {
    final digits = (value ?? '').trim();
    if (digits.isEmpty) {
      return 'Enter your mobile number';
    }
    if (JordanPhoneField.composeE164(digits) == null) {
      return 'Use 9 digits starting with 7 (example: 7XXXXXXXX)';
    }
    return null;
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldError = null);

    final digits = _phoneController.text.trim();
    final error = _validateNational(digits);
    if (error != null) {
      setState(() => _fieldError = error);
      return;
    }

    final e164 = JordanPhoneField.composeE164(digits)!;

    AuthService.instance.setSignUpRole(_accountType);
    setState(() => _submitting = true);
    try {
      await AuthService.instance.startPhoneSignIn(e164);
      if (!mounted) {
        return;
      }
      if (AuthService.instance.currentUser != null) {
        final home = await SessionGate.resolveHome();
        if (!mounted) {
          return;
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => home),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => OtpScreen(phoneE164: e164),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not send verification code.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on TimeoutException catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Check your connection and try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppGradients.heroDark
              : AppGradients.hero(context),
        ),
        child: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
                      vertical: AppSpacing.screenVertical,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        const ChargixBrandLockup(compact: true),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Sign in',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'We will text you a one-time code to verify your number.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment(
                              value: UserRole.user,
                              label: Text('Driver'),
                              icon: Icon(Icons.directions_car_rounded),
                            ),
                            ButtonSegment(
                              value: UserRole.station,
                              label: Text('Station'),
                              icon: Icon(Icons.storefront_rounded),
                            ),
                          ],
                          selected: {_accountType},
                          onSelectionChanged: (s) {
                            setState(() => _accountType = s.first);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        JordanPhoneField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          errorText: _fieldError,
                          onSubmitted: (_) => _continue(),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _submitting ? null : _continue,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _submitting
                                ? const SizedBox(
                                    key: ValueKey('l'),
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    key: ValueKey('t'),
                                    'Continue',
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'By continuing you agree to receive SMS messages for verification.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
