import 'fuel_type.dart';

class CurrentPrice {
  final String stationId;
  final FuelType fuelType;
  final double price;
  final DateTime updatedAt;
  final int reportCount;

  const CurrentPrice({
    required this.stationId,
    required this.fuelType,
    required this.price,
    required this.updatedAt,
    required this.reportCount,
  });

  factory CurrentPrice.fromJson(Map<String, dynamic> json) {
    return CurrentPrice(
      stationId: json['stationId'] as String,
      fuelType: FuelType.values.byName(json['fuelType'] as String),
      price: (json['price'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reportCount: json['reportCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'fuelType': fuelType.name,
      'price': price,
      'updatedAt': updatedAt.toIso8601String(),
      'reportCount': reportCount,
    };
  }
}
