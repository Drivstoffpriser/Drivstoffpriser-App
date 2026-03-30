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

enum SubmissionStatus { pending, approved, rejected }

class StationSubmission {
  final String id;
  final String name;
  final String brand;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String submittedBy;
  final DateTime? submittedAt;
  final SubmissionStatus status;
  final String? feedback;
  final bool feedbackRead;

  const StationSubmission({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.submittedBy,
    this.submittedAt,
    this.status = SubmissionStatus.pending,
    this.feedback,
    this.feedbackRead = false,
  });

  factory StationSubmission.fromJson(String id, Map<String, dynamic> json) {
    return StationSubmission(
      id: id,
      name: json['name'] as String,
      brand: json['brand'] as String,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      submittedBy: json['submittedBy'] as String,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
      status: SubmissionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SubmissionStatus.pending,
      ),
      feedback: json['feedback'] as String?,
      feedbackRead: json['feedbackRead'] as bool? ?? false,
    );
  }
}
