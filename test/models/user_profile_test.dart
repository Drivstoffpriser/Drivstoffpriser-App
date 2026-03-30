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

import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_price_tracker/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    const json = {
      'id': 'uid_abc',
      'displayName': 'TestUser',
      'reportCount': 42,
      'trustScore': 0.95,
    };

    test('fromJson creates valid UserProfile', () {
      final profile = UserProfile.fromJson(json);
      expect(profile.id, 'uid_abc');
      expect(profile.displayName, 'TestUser');
      expect(profile.reportCount, 42);
      expect(profile.trustScore, 0.95);
    });

    test('toJson produces correct map', () {
      final profile = UserProfile.fromJson(json);
      expect(profile.toJson(), json);
    });

    test('fromJson handles int trustScore', () {
      final intJson = Map<String, dynamic>.from(json);
      intJson['trustScore'] = 1;
      final profile = UserProfile.fromJson(intJson);
      expect(profile.trustScore, 1.0);
    });

    test('roundtrip preserves all fields', () {
      final profile = UserProfile.fromJson(json);
      final roundtripped = UserProfile.fromJson(profile.toJson());
      expect(roundtripped.id, profile.id);
      expect(roundtripped.displayName, profile.displayName);
      expect(roundtripped.reportCount, profile.reportCount);
      expect(roundtripped.trustScore, profile.trustScore);
    });
  });
}
