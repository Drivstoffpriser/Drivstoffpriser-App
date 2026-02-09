import 'package:cloud_firestore/cloud_firestore.dart';

class BugReport {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String userId;
  final String deviceName;
  final String osVersion;
  final String appVersion;
  final bool synced;

  BugReport({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.userId,
    required this.deviceName,
    required this.osVersion,
    required this.appVersion,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
      'deviceName': deviceName,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'synced': synced,
    };
  }

  factory BugReport.fromMap(String id, Map<String, dynamic> map) {
    return BugReport(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] ?? 'anonymous',
      deviceName: map['deviceName'] ?? 'unknown',
      osVersion: map['osVersion'] ?? 'unknown',
      appVersion: map['appVersion'] ?? '1.0.0',
      synced: map['synced'] ?? false,
    );
  }
}
