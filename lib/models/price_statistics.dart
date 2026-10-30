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

class ProviderPriceDayPoint {
  final DateTime date;
  final double price;
  const ProviderPriceDayPoint({required this.date, required this.price});
}

class PriceExtremes {
  final double? highestPrice;
  final String? highestStationId;
  final String? highestStationName;
  final double? lowestPrice;
  final String? lowestStationId;
  final String? lowestStationName;

  const PriceExtremes({
    required this.highestPrice,
    this.highestStationId,
    required this.highestStationName,
    required this.lowestPrice,
    this.lowestStationId,
    required this.lowestStationName,
  });

  factory PriceExtremes.fromJson(Map<String, dynamic> json) {
    return PriceExtremes(
      highestPrice: json['highestPrice'] != null
          ? double.parse(json['highestPrice'] as String)
          : null,
      highestStationId: json['highestStationId'] as String?,
      highestStationName: json['highestStationName'] as String?,
      lowestPrice: json['lowestPrice'] != null
          ? double.parse(json['lowestPrice'] as String)
          : null,
      lowestStationId: json['lowestStationId'] as String?,
      lowestStationName: json['lowestStationName'] as String?,
    );
  }
}

class ActivityStats {
  final int last24Hours;
  final int last7Days;
  final int last30Days;

  const ActivityStats({
    required this.last24Hours,
    required this.last7Days,
    required this.last30Days,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      last24Hours: json['last24Hours'] as int,
      last7Days: json['last7Days'] as int,
      last30Days: json['last30Days'] as int,
    );
  }
}

class Contributor {
  final String? displayName;
  final int count;

  const Contributor({required this.displayName, required this.count});

  factory Contributor.fromJson(Map<String, dynamic> json) {
    return Contributor(
      displayName: json['displayName'] as String?,
      count: json['count'] as int,
    );
  }
}

class ContributorStats {
  final List<Contributor> last24Hours;
  final List<Contributor> total;

  const ContributorStats({required this.last24Hours, required this.total});

  factory ContributorStats.fromJson(Map<String, dynamic> json) {
    List<Contributor> parse(List<dynamic> raw) => raw
        .map((e) => Contributor.fromJson(e as Map<String, dynamic>))
        .toList();

    return ContributorStats(
      last24Hours: parse(json['last24Hours'] as List<dynamic>),
      total: parse(json['total'] as List<dynamic>),
    );
  }
}

class PriceStatistics {
  final Map<FuelType, PriceExtremes> allStationsExtremes;
  final Map<FuelType, PriceExtremes> nearbyStationsExtremes;
  final ActivityStats activity;

  const PriceStatistics({
    required this.allStationsExtremes,
    required this.nearbyStationsExtremes,
    required this.activity,
  });

  factory PriceStatistics.fromJson(Map<String, dynamic> json) {
    Map<FuelType, PriceExtremes> parseExtremes(Map<String, dynamic> raw) {
      return {
        for (final entry in raw.entries)
          FuelType.fromBackendString(entry.key): PriceExtremes.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      };
    }

    return PriceStatistics(
      allStationsExtremes: parseExtremes(
        json['allStations'] as Map<String, dynamic>,
      ),
      nearbyStationsExtremes: {},
      activity: ActivityStats.fromJson(
        json['activity'] as Map<String, dynamic>,
      ),
    );
  }
}
