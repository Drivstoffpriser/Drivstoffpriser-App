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
