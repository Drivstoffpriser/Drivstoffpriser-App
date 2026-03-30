/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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
