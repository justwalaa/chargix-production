import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/result/data_state.dart';
import '../data/chargix_data.dart';
import '../data/repositories/user_repository.dart';
import '../models/enums/user_role.dart';
import '../models/user_model.dart';

/// Centralized auth: Firebase Phone Auth + Firestore user profile via [UserRepository].
class AuthService {
  AuthService._({UserRepository? userRepository})
      : _users = userRepository ?? ChargixData.users;

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _users;

  String? _verificationId;
  int? _resendToken;
  String? _lastRequestedPhoneE164;

  String? get lastRequestedPhoneE164 => _lastRequestedPhoneE164;

  UserRole _signUpRole = UserRole.user;

  void setSignUpRole(UserRole role) => _signUpRole = role;

  Future<UserModel?> fetchCurrentProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    final result = await _users.getUser(uid);
    return result is DataSuccess<UserModel> ? result.data : null;
  }

  bool get _firebaseAppReady {
    try {
      return Firebase.apps.isNotEmpty;
    } on Object catch (_) {
      return false;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// True when phone-authenticated and profile exists in Firestore.
  Future<bool> hasValidSession() async {
    if (!_firebaseAppReady) {
      return false;
    }
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    final phone = user.phoneNumber ?? _lastRequestedPhoneE164;
    if (phone == null || phone.isEmpty) {
      await signOut();
      return false;
    }
    final profile = await _users.getUser(user.uid);
    return profile is DataSuccess<UserModel>;
  }

  /// Sends SMS via Firebase Phone Auth (or throws if Firebase is not initialized).
  Future<void> startPhoneSignIn(String e164Phone) async {
    if (!_firebaseAppReady) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not initialized on this build.',
      );
    }
    _lastRequestedPhoneE164 = e164Phone;
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 90),
      forceResendingToken: null,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          await _persistUserIfNeeded(e164Phone);
        } on Object catch (e, st) {
          debugPrint('Chargix: auto verification failed: $e\n$st');
        } finally {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId ??= verificationId;
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 95),
      onTimeout: () => throw TimeoutException('Phone verification timed out.'),
    );
  }

  /// Resend OTP SMS using Firebase [forceResendingToken] when available.
  Future<void> resendPhoneOtp(String e164Phone) async {
    if (!_firebaseAppReady) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not initialized on this build.',
      );
    }
    _lastRequestedPhoneE164 = e164Phone;
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 90),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          await _persistUserIfNeeded(e164Phone);
        } on Object catch (e, st) {
          debugPrint('Chargix: auto verification (resend) failed: $e\n$st');
        } finally {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId ??= verificationId;
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 95),
      onTimeout: () => throw TimeoutException('Resend verification timed out.'),
    );
  }

  /// Confirms the 6-digit SMS code and creates/updates the user document.
  Future<UserCredential> submitSmsCode(String smsCode) async {
    if (!_firebaseAppReady) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not initialized on this build.',
      );
    }
    final vid = _verificationId;
    if (vid == null) {
      throw FirebaseAuthException(
        code: 'invalid-verification-id',
        message: 'Request a new code before verifying.',
      );
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: vid,
      smsCode: smsCode.trim(),
    );
    final cred = await _auth.signInWithCredential(credential);
    final phone = _lastRequestedPhoneE164 ?? cred.user?.phoneNumber ?? '';
    if (phone.isNotEmpty) {
      await _persistUserIfNeeded(phone);
    }
    return cred;
  }

  Future<void> _persistUserIfNeeded(String phoneE164) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final exists = await _users.getUser(user.uid);
    final isNew = exists is! DataSuccess<UserModel>;
    String? stationId;

    // Partner stations are created via station-owner onboarding (pending approval).
    if (_signUpRole.isStation && isNew) {
      stationId = user.uid;
    }

    final result = await _users.ensureUserAfterSignIn(
      uid: user.uid,
      phoneE164: phoneE164,
      role: _signUpRole,
      stationId: stationId,
    );
    if (result is DataError<UserModel>) {
      debugPrint('Chargix: ensureUserAfterSignIn failed: ${result.error}');
      throw FirebaseAuthException(
        code: 'user-profile-failed',
        message: 'Signed in but could not save your profile. Try again.',
      );
    }
  }

  Future<void> signOut() async {
    _verificationId = null;
    _resendToken = null;
    _lastRequestedPhoneE164 = null;
    _signUpRole = UserRole.user;
    await _auth.signOut();
  }
}
