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

import 'package:flutter/foundation.dart';

import '../models/fuel_type.dart';
import '../models/price_history_point.dart';
import '../models/price_report.dart';
import '../services/firestore_service.dart';

class PriceProvider extends ChangeNotifier {
  static const Duration cooldownDuration = Duration(hours: 1);

  List<PriceReport> _reports = [];
  Map<FuelType, List<PriceHistoryPoint>> _history = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isLoadingHistory = false;
  String? _error;

  List<PriceReport> get reports => _reports;
  Map<FuelType, List<PriceHistoryPoint>> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  Future<void> loadReports(String stationId) async {
    _isLoading = true;
    notifyListeners();

    _reports = await FirestoreService.getReports(stationId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory(String stationId) async {
    _isLoadingHistory = true;
    notifyListeners();

    _history = await FirestoreService.getPriceHistory(stationId);
    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Returns the remaining cooldown duration, or null if no cooldown is active.
  Future<Duration?> getCooldownRemaining({
    required String userId,
    required String stationId,
    required FuelType fuelType,
  }) async {
    final lastReport = await FirestoreService.getLastReportTime(
      userId: userId,
      stationId: stationId,
      fuelType: fuelType,
    );
    if (lastReport == null) return null;

    final elapsed = DateTime.now().difference(lastReport);
    if (elapsed >= cooldownDuration) return null;

    return cooldownDuration - elapsed;
  }

  Future<bool> submitReport({
    required String stationId,
    required FuelType fuelType,
    required double price,
    required String userId,
    bool incrementUserReport = false,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await FirestoreService.submitReport(
        stationId: stationId,
        fuelType: fuelType,
        price: price,
        userId: userId,
        incrementUserReport: incrementUserReport,
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
