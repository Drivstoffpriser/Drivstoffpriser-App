import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_station_ids';

  /// Load favorite station IDs from local storage.
  static Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList(_key);
    return favorites?.toSet() ?? {};
  }

  /// Save favorite station IDs to local storage.
  static Future<void> saveFavorites(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
