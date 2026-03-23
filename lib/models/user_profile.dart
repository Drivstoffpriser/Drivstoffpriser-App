class UserProfile {
  final String id;
  final String displayName;
  final int reportCount;
  final double trustScore;
  final bool isAdmin;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.reportCount,
    required this.trustScore,
    this.isAdmin = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      reportCount: json['reportCount'] as int,
      trustScore: (json['trustScore'] as num).toDouble(),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'reportCount': reportCount,
      'trustScore': trustScore,
    };
  }
}
