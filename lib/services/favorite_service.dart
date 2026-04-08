import 'backend_api_client.dart';

class FavoriteService {
  static final BackendApiClient _client = BackendApiClient();

  static Future<Set<String>> getFavorites() async {
    return _client.getFavorites();
  }

  static Future<void> addFavorite(String stationId) async {
    await _client.addFavorite(stationId);
  }

  static Future<void> removeFavorite(String stationId) async {
    await _client.removeFavorite(stationId);
  }

  static Future<bool> isFavorite(String stationId) async {
    final favorites = await getFavorites();
    return favorites.contains(stationId);
  }

  static Future<void> toggleFavorite(String stationId) async {
    if (await isFavorite(stationId)) {
      await removeFavorite(stationId);
    } else {
      await addFavorite(stationId);
    }
  }
}
