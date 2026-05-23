import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/favorite_station_model.dart';
import 'base_firestore_service.dart';

class FavoritesFirestoreService extends BaseFirestoreService {
  FavoritesFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> get _favorites =>
      collection(FirestorePaths.favorites);

  String docId(String userId, String stationId) => '${userId}_$stationId';

  Stream<List<FavoriteStationModel>> watchFavoritesForUser(String userId) {
    return runStream(
      () => _favorites
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snap) {
            return snap.docs
                .map((d) => parseDoc(d, FavoriteStationModel.fromMap))
                .toList();
          }),
      context: 'watchFavoritesForUser',
    );
  }

  Stream<Set<String>> watchFavoriteStationIds(String userId) {
    return watchFavoritesForUser(userId)
        .map((list) => list.map((f) => f.stationId).toSet());
  }

  Future<void> addFavorite(FavoriteStationModel favorite) => run(() async {
        await _favorites.doc(favorite.id).set(
              withWriteTimestamps(
                data: favorite.toMap(),
                isCreate: true,
              ),
              SetOptions(merge: true),
            );
      }, context: 'addFavorite');

  Future<void> removeFavorite(String userId, String stationId) => run(() async {
        await _favorites.doc(docId(userId, stationId)).delete();
      }, context: 'removeFavorite');

  Future<bool> isFavorite(String userId, String stationId) => run(() async {
        final snap = await _favorites.doc(docId(userId, stationId)).get();
        return snap.exists;
      }, context: 'isFavorite');
}
