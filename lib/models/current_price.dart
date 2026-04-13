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

import 'fuel_type.dart';

class CurrentPrice {
  final String stationId;
  final FuelType fuelType;
  final double price;
  final DateTime? updatedAt;
  final int reportCount;

  bool get isEstimate => updatedAt == null;

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
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      reportCount: json['reportCount'] as int,
    );
  }

  factory CurrentPrice.fromBackendJson(
    String stationId,
    Map<String, dynamic> json,
  ) {
    return CurrentPrice(
      stationId: stationId,
      fuelType: FuelType.fromBackendString(json['fuelType'] as String),
      price: double.parse(json['price'] as String),
      updatedAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'] as String)
          : null,
      reportCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'fuelType': fuelType.name,
      'price': price,
      'updatedAt': updatedAt?.toIso8601String(),
      'reportCount': reportCount,
    };
  }
}
