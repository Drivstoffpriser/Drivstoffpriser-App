import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _favoritesKey = 'favorite_stations';

  static Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? [];
    return list.toSet();
  }

  static Future<void> addFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.add(stationId);
    await prefs.setStringList(_favoritesKey, favorites.toList());
  }

  static Future<void> removeFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(stationId);
    await prefs.setStringList(_favoritesKey, favorites.toList());
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
