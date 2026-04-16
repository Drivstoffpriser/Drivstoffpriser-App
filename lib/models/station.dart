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

import 'current_price.dart';
import 'fuel_type.dart';

const _providerToDisplayName = {
  'AUTOMAT_1': 'Automat1',
  'BEST': 'Best',
  'BUNKER_OIL': 'Bunker Oil',
  'CIRCLE_K': 'Circle K',
  'DRIV': 'Driv',
  'ESSO': 'Esso',
  'HALTBAKK_EXPRESS': 'Haltbakk Express',
  'OLJELEVERANDØREN': 'Oljeleverandøren',
  'ST1': 'St1',
  'TANKEN': 'Tanken',
  'TRONDER_OIL': 'Trønder Oil',
  'UNO_X': 'Uno-X',
  'YX': 'YX',
  'YX_TRUCK': 'YX Truck',
};

class Station {
  final String id;
  final String name;
  final String brand;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final Map<FuelType, CurrentPrice> prices;

  const Station({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.prices = const {},
  });

  /// Returns a copy of this station with the given prices merged in.
  Station copyWithPrices(Map<FuelType, CurrentPrice> newPrices) {
    return Station(
      id: id,
      name: name,
      brand: brand,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      prices: newPrices,
    );
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['prices'] as List<dynamic>? ?? [];
    final prices = <FuelType, CurrentPrice>{};
    for (final p in rawPrices) {
      final price = CurrentPrice.fromJson(p as Map<String, dynamic>);
      prices[price.fuelType] = price;
    }
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      prices: prices,
    );
  }

  factory Station.fromBackendJson(Map<String, dynamic> json) {
    final provider = json['provider'] as String;
    final location = json['location'] as Map<String, dynamic>;
    final stationId = json['id'] as String;
    final rawPrices = json['prices'] as List<dynamic>? ?? [];
    final prices = <FuelType, CurrentPrice>{};
    for (final p in rawPrices) {
      final price = CurrentPrice.fromBackendJson(
        stationId,
        p as Map<String, dynamic>,
      );
      prices[price.fuelType] = price;
    }
    return Station(
      id: stationId,
      name: json['name'] as String,
      brand: _providerToDisplayName[provider] ?? provider,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
      prices: prices,
    );
  }

  /// Parses a station from the `/stations/all` endpoint (no prices).
  factory Station.fromBaseJson(Map<String, dynamic> json) {
    final provider = json['provider'] as String;
    final location = json['location'] as Map<String, dynamic>;
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: _providerToDisplayName[provider] ?? provider,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'prices': prices.values.map((p) => p.toJson()).toList(),
    };
  }
}
