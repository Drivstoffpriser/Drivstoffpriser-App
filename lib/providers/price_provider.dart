import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/fuel_type.dart';
import '../models/price_history_point.dart';
import '../models/price_report.dart';
import '../services/mock_data_service.dart';

class PriceProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  List<PriceReport> _reports = [];
  Map<FuelType, List<PriceHistoryPoint>> _history = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isLoadingHistory = false;

  List<PriceReport> get reports => _reports;
  Map<FuelType, List<PriceHistoryPoint>> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingHistory => _isLoadingHistory;

  Future<void> loadReports(String stationId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    _reports = MockDataService.getReportsForStation(stationId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory(String stationId) async {
    _isLoadingHistory = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    _history = MockDataService.getPriceHistory(stationId);
    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<bool> submitReport({
    required String stationId,
    required FuelType fuelType,
    required double price,
    required String userId,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final report = PriceReport(
      id: _uuid.v4(),
      stationId: stationId,
      fuelType: fuelType,
      price: price,
      userId: userId,
      reportedAt: DateTime.now(),
    );

    _reports.insert(0, report);
    _isSubmitting = false;
    notifyListeners();
    return true;
  }
}
