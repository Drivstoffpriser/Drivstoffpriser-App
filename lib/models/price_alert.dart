import 'fuel_type.dart';

class PriceAlert {
  final String id;
  final String userId;
  final FuelType fuelType;
  final double targetPrice;
  final String? stationId;
  final double maxDistanceKm;
  final double userLat;
  final double userLng;
  final DateTime createdAt;
  final bool isActive;

  const PriceAlert({
    required this.id,
    required this.userId,
    required this.fuelType,
    required this.targetPrice,
    this.stationId,
    this.maxDistanceKm = 5,
    required this.userLat,
    required this.userLng,
    required this.createdAt,
    this.isActive = true,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fuelType: FuelType.values.byName(json['fuelType'] as String),
      targetPrice: (json['targetPrice'] as num).toDouble(),
      stationId: json['stationId'] as String?,
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble() ?? 5,
      userLat: (json['userLat'] as num).toDouble(),
      userLng: (json['userLng'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fuelType': fuelType.name,
      'targetPrice': targetPrice,
      'stationId': stationId,
      'maxDistanceKm': maxDistanceKm,
      'userLat': userLat,
      'userLng': userLng,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  PriceAlert copyWith({bool? isActive}) {
    return PriceAlert(
      id: id,
      userId: userId,
      fuelType: fuelType,
      targetPrice: targetPrice,
      stationId: stationId,
      maxDistanceKm: maxDistanceKm,
      userLat: userLat,
      userLng: userLng,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
