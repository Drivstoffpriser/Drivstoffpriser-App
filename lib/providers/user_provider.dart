import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _user = const UserProfile(
    id: 'user-mock-1',
    displayName: 'Anonymous',
    reportCount: 0,
    trustScore: 1.0,
  );

  bool _isDarkMode = false;

  UserProfile get user => _user;
  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void incrementReportCount() {
    _user = UserProfile(
      id: _user.id,
      displayName: _user.displayName,
      reportCount: _user.reportCount + 1,
      trustScore: _user.trustScore,
    );
    notifyListeners();
  }
}
