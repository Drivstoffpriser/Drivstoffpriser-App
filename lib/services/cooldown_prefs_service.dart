import 'package:shared_preferences/shared_preferences.dart';

class CooldownPrefsService {
  static const _skipConfirmKey = 'skip_submit_confirmation';

  static Future<bool> shouldSkipConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipConfirmKey) ?? false;
  }

  static Future<void> setSkipConfirmation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipConfirmKey, value);
  }
}
