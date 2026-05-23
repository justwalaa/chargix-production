import '../../../core/result/data_state.dart';
import '../../../models/favorite_station_model.dart';
import '../../firestore/favorites_firestore_service.dart';

class FavoritesRepository {
  FavoritesRepository({FavoritesFirestoreService? service})
      : _service = service ?? FavoritesFirestoreService();

  static final FavoritesRepository instance = FavoritesRepository();

  final FavoritesFirestoreService _service;

  Stream<List<FavoriteStationModel>> watchFavoritesForUser(String userId) =>
      _service.watchFavoritesForUser(userId);

  Stream<Set<String>> watchFavoriteStationIds(String userId) =>
      _service.watchFavoriteStationIds(userId);

  Future<DataState<void>> toggleFavorite({
    required String userId,
    required String stationId,
    required bool add,
  }) async {
    try {
      if (add) {
        final fav = FavoriteStationModel(
          id: _service.docId(userId, stationId),
          userId: userId,
          stationId: stationId,
          createdAt: DateTime.now(),
        );
        await _service.addFavorite(fav);
      } else {
        await _service.removeFavorite(userId, stationId);
      }
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }
}
