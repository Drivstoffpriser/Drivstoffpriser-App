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

enum ModifyRequestStatus { pending, approved, rejected }

class StationModifyRequest {
  final String id;
  final String stationId;

  // Original values
  final String originalName;
  final String originalBrand;
  final String originalAddress;
  final String originalCity;
  final double originalLatitude;
  final double originalLongitude;

  // Proposed values
  final String proposedName;
  final String proposedBrand;
  final String proposedAddress;
  final String proposedCity;
  final double proposedLatitude;
  final double proposedLongitude;

  final String submittedBy;
  final DateTime? submittedAt;
  final ModifyRequestStatus status;
  final String? feedback;
  final bool feedbackRead;
  final String? proposedLogoUrl;

  const StationModifyRequest({
    required this.id,
    required this.stationId,
    required this.originalName,
    required this.originalBrand,
    required this.originalAddress,
    required this.originalCity,
    required this.originalLatitude,
    required this.originalLongitude,
    required this.proposedName,
    required this.proposedBrand,
    required this.proposedAddress,
    required this.proposedCity,
    required this.proposedLatitude,
    required this.proposedLongitude,
    required this.submittedBy,
    this.submittedAt,
    this.status = ModifyRequestStatus.pending,
    this.feedback,
    this.feedbackRead = false,
    this.proposedLogoUrl,
  });

  bool get nameChanged => originalName != proposedName;
  bool get brandChanged => originalBrand != proposedBrand;
  bool get addressChanged => originalAddress != proposedAddress;
  bool get cityChanged => originalCity != proposedCity;
  bool get locationChanged =>
      originalLatitude != proposedLatitude ||
      originalLongitude != proposedLongitude;
  bool get logoChanged => proposedLogoUrl != null;
  bool get hasChanges =>
      nameChanged ||
      brandChanged ||
      addressChanged ||
      cityChanged ||
      locationChanged ||
      logoChanged;

  factory StationModifyRequest.fromJson(String id, Map<String, dynamic> json) {
    return StationModifyRequest(
      id: id,
      stationId: json['stationId'] as String,
      originalName: json['originalName'] as String,
      originalBrand: json['originalBrand'] as String,
      originalAddress: json['originalAddress'] as String? ?? '',
      originalCity: json['originalCity'] as String? ?? '',
      originalLatitude: (json['originalLatitude'] as num).toDouble(),
      originalLongitude: (json['originalLongitude'] as num).toDouble(),
      proposedName: json['proposedName'] as String,
      proposedBrand: json['proposedBrand'] as String,
      proposedAddress: json['proposedAddress'] as String? ?? '',
      proposedCity: json['proposedCity'] as String? ?? '',
      proposedLatitude: (json['proposedLatitude'] as num).toDouble(),
      proposedLongitude: (json['proposedLongitude'] as num).toDouble(),
      submittedBy: json['submittedBy'] as String,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
      status: ModifyRequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ModifyRequestStatus.pending,
      ),
      feedback: json['feedback'] as String?,
      feedbackRead: json['feedbackRead'] as bool? ?? false,
      proposedLogoUrl: json['proposedLogoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'originalName': originalName,
      'originalBrand': originalBrand,
      'originalAddress': originalAddress,
      'originalCity': originalCity,
      'originalLatitude': originalLatitude,
      'originalLongitude': originalLongitude,
      'proposedName': proposedName,
      'proposedBrand': proposedBrand,
      'proposedAddress': proposedAddress,
      'proposedCity': proposedCity,
      'proposedLatitude': proposedLatitude,
      'proposedLongitude': proposedLongitude,
      'submittedBy': submittedBy,
      'status': status.name,
      'proposedLogoUrl': ?proposedLogoUrl,
    };
  }
}
