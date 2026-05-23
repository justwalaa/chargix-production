import 'package:firebase_core/firebase_core.dart';

/// Application-level errors surfaced from repositories and services.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

/// Firestore / Firebase operation failed.
final class FirestoreAppException extends AppException {
  const FirestoreAppException(super.message, {super.code});

  factory FirestoreAppException.fromFirebaseException(
    Object error, {
    String? fallbackMessage,
  }) {
    if (error is FirebaseException) {
      return FirestoreAppException(
        error.message ?? fallbackMessage ?? 'Firestore operation failed.',
        code: error.code,
      );
    }
    return FirestoreAppException(
      fallbackMessage ?? error.toString(),
      code: 'unknown',
    );
  }
}
