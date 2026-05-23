import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/firebase/firestore_guard.dart';

/// Shared Firestore instance access and document parsing.
abstract class BaseFirestoreService {
  BaseFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  FirebaseFirestore get db => _db;

  bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } on Object catch (_) {
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _db.doc(path);
  }

  T parseDoc<T>(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    T Function(Map<String, dynamic> data) fromMap,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Document ${snapshot.id} has no data.');
    }
    final withId = Map<String, dynamic>.from(data);
    withId['id'] ??= snapshot.id;
    if (withId['uid'] == null && snapshot.reference.path.contains('users')) {
      withId['uid'] = snapshot.id;
    }
    return fromMap(withId);
  }

  Map<String, dynamic> withWriteTimestamps({
    required Map<String, dynamic> data,
    required bool isCreate,
  }) {
    return {
      ...data,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<T> run<T>(Future<T> Function() fn, {String? context}) {
    return guardFirestore(fn, context: context);
  }

  Stream<T> runStream<T>(Stream<T> Function() fn, {String? context}) {
    return guardFirestoreStream(fn, context: context);
  }
}
