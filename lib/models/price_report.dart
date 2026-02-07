import 'fuel_type.dart';

class PriceReport {
  final String id;
  final String stationId;
  final FuelType fuelType;
  final double price;
  final String userId;
  final DateTime reportedAt;

  const PriceReport({
    required this.id,
    required this.stationId,
    required this.fuelType,
    required this.price,
    required this.userId,
    required this.reportedAt,
  });

  factory PriceReport.fromJson(Map<String, dynamic> json) {
    return PriceReport(
      id: json['id'] as String,
      stationId: json['stationId'] as String,
      fuelType: FuelType.values.byName(json['fuelType'] as String),
      price: (json['price'] as num).toDouble(),
      userId: json['userId'] as String,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationId': stationId,
      'fuelType': fuelType.name,
      'price': price,
      'userId': userId,
      'reportedAt': reportedAt.toIso8601String(),
    };
  }
}
