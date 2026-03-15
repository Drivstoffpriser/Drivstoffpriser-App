import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';

import 'distance_service.dart';

const _tag = 'ImageMetadata';

/// Metadata extracted from photo EXIF data.
class ImageMetadata {
  final double? latitude;
  final double? longitude;
  final DateTime? dateTime;

  const ImageMetadata({this.latitude, this.longitude, this.dateTime});

  bool get hasLocation =>
      latitude != null && longitude != null &&
      !latitude!.isNaN && !longitude!.isNaN;
  bool get hasDateTime => dateTime != null;

  /// Whether the photo was taken within the last 24 hours.
  bool get isTakenWithin24Hours {
    if (dateTime == null) return false;
    return DateTime.now().difference(dateTime!).inHours < 24;
  }

  /// Whether the photo location is within [maxMeters] of the given station.
  bool isNearStation(double stationLat, double stationLng,
      {double maxMeters = 1000}) {
    if (!hasLocation) return false;
    final distance = DistanceService.distanceInMeters(
      latitude!, longitude!, stationLat, stationLng,
    );
    return distance <= maxMeters;
  }

  /// Full validation: photo has GPS within 1km of station AND taken in last 24h.
  bool isValidForStation(double stationLat, double stationLng,
      {double maxMeters = 1000}) {
    return isTakenWithin24Hours && isNearStation(stationLat, stationLng, maxMeters: maxMeters);
  }
}

class ImageMetadataService {
  /// Extract EXIF metadata (GPS + datetime) from image bytes.
  static Future<ImageMetadata> extractMetadata(Uint8List bytes) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) {
        debugPrint('[$_tag] No EXIF data found');
        return const ImageMetadata();
      }

      final lat = _extractLatLng(tags, 'GPS GPSLatitude', 'GPS GPSLatitudeRef');
      final lng = _extractLatLng(tags, 'GPS GPSLongitude', 'GPS GPSLongitudeRef');
      final dateTime = _extractDateTime(tags);

      debugPrint('[$_tag] Extracted: lat=$lat, lng=$lng, dateTime=$dateTime');
      return ImageMetadata(latitude: lat, longitude: lng, dateTime: dateTime);
    } catch (e, stack) {
      debugPrint('[$_tag] Failed to read EXIF: $e\n$stack');
      return const ImageMetadata();
    }
  }

  /// Parse GPS coordinate from EXIF tags (degrees, minutes, seconds → decimal).
  static double? _extractLatLng(
      Map<String, IfdTag> tags, String coordKey, String refKey) {
    final coordTag = tags[coordKey];
    final refTag = tags[refKey];
    if (coordTag == null) return null;

    final values = coordTag.values;
    if (values is! IfdRatios || values.ratios.length < 3) return null;

    final degrees = _ratioToDouble(values.ratios[0]);
    final minutes = _ratioToDouble(values.ratios[1]);
    final seconds = _ratioToDouble(values.ratios[2]);

    if (degrees == null || minutes == null || seconds == null) return null;

    var decimal = degrees + minutes / 60 + seconds / 3600;

    // S or W means negative
    final ref = refTag?.printable ?? '';
    if (ref == 'S' || ref == 'W') decimal = -decimal;

    return decimal;
  }

  /// Parse datetime from EXIF DateTimeOriginal or DateTime tag.
  static DateTime? _extractDateTime(Map<String, IfdTag> tags) {
    final dateStr = tags['EXIF DateTimeOriginal']?.printable ??
        tags['Image DateTime']?.printable;
    if (dateStr == null) return null;

    // EXIF format: "2026:03:08 15:54:03" → "2026-03-08 15:54:03"
    try {
      final normalized = dateStr.replaceFirstMapped(
        RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
        (m) => '${m[1]}-${m[2]}-${m[3]}',
      );
      return DateTime.parse(normalized);
    } catch (e) {
      debugPrint('[$_tag] Failed to parse date "$dateStr": $e');
      return null;
    }
  }

  /// Safely convert a Ratio to double, returning null if denominator is 0.
  static double? _ratioToDouble(Ratio ratio) {
    if (ratio.denominator == 0) return null;
    return ratio.numerator / ratio.denominator;
  }
}
