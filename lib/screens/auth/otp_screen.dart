import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/routing/session_gate.dart';
import '../../services/auth_service.dart';
import '../../theme/app_gradients.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/auth/otp_six_fields.dart';
import '../../widgets/chargix/chargix_brand_lockup.dart';

/// Six-digit SMS verification with resend cooldown and Firebase Phone Auth submit.
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneE164,
  });

  final String phoneE164;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final GlobalKey<OtpSixFieldsState> _otpKey = GlobalKey<OtpSixFieldsState>();

  String _code = '';
  bool _verifying = false;
  bool _resending = false;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  String get _maskedPhone {
    final p = widget.phoneE164;
    if (p.length < 8) {
      return p;
    }
    final tail = p.substring(p.length - 2);
    return '${p.substring(0, 4)} ••••• $tail';
  }

  Future<void> _verify(String code) async {
    if (code.length != 6 || _verifying) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      await AuthService.instance.submitSmsCode(code);
      if (!mounted) {
        return;
      }
      final home = await SessionGate.resolveHome();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => home),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      _otpKey.currentState?.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Invalid code. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) {
      return;
    }
    setState(() => _resending = true);
    try {
      await AuthService.instance.resendPhoneOtp(widget.phoneE164);
      if (!mounted) {
        return;
      }
      _otpKey.currentState?.clear();
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new code has been sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not resend code.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on TimeoutException catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resend timed out. Try again shortly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canResend = _cooldown == 0 && !_resending;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _verifying ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  const ChargixBrandLockup(compact: true, showTagline: false),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Enter code',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sent to $_maskedPhone',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OtpSixFields(
                    key: _otpKey,
                    enabled: !_verifying,
                    onChanged: (c) => setState(() => _code = c),
                    onCompleted: _verify,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _cooldown > 0
                            ? 'Resend in ${_cooldown}s'
                            : 'Did not receive a code?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      if (_cooldown == 0) ...[
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: canResend ? _resend : null,
                          child: _resending
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                )
                              : const Text('Resend'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton(
                    onPressed: (_code.length == 6 && !_verifying)
                        ? () => _verify(_code)
                        : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _verifying
                          ? const SizedBox(
                              key: ValueKey('v'),
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              key: ValueKey('t'),
                              'Verify & continue',
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
