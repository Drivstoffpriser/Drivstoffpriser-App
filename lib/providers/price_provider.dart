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
