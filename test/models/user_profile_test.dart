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
