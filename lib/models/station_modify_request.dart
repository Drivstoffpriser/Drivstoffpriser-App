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
  });

  bool get nameChanged => originalName != proposedName;
  bool get brandChanged => originalBrand != proposedBrand;
  bool get addressChanged => originalAddress != proposedAddress;
  bool get cityChanged => originalCity != proposedCity;
  bool get locationChanged =>
      originalLatitude != proposedLatitude ||
      originalLongitude != proposedLongitude;
  bool get hasChanges =>
      nameChanged ||
      brandChanged ||
      addressChanged ||
      cityChanged ||
      locationChanged;

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
    };
  }
}
