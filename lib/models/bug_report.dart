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
