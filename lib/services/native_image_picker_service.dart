import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_metadata_service.dart';

const _tag = 'NativeImagePicker';

/// Result from native image picker that includes unredacted EXIF metadata.
class NativePickResult {
  final String path;
  final ImageMetadata metadata;

  const NativePickResult({required this.path, required this.metadata});
}

/// Picks images using a native Android method channel to preserve GPS EXIF data.
///
/// Android's ContentResolver redacts GPS from copied images. The native picker
/// reads EXIF from the original content URI via [MediaStore.setRequireOriginal]
/// before copying, so GPS coordinates are preserved.
class NativeImagePickerService {
  static const _channel = MethodChannel('no.fueltracker/image_metadata');

  /// Pick an image from the gallery with full EXIF metadata (including GPS).
  /// Returns null if the user cancels.
  static Future<NativePickResult?> pickImageFromGallery() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'pickImageWithMetadata',
      );

      if (result == null) {
        debugPrint('[$_tag] User cancelled picker');
        return null;
      }

      final path = result['path'] as String?;
      if (path == null) {
        debugPrint('[$_tag] No path returned');
        return null;
      }

      final lat = result['latitude'] as double?;
      final lng = result['longitude'] as double?;
      final dateTimeStr = result['dateTime'] as String?;

      DateTime? dateTime;
      if (dateTimeStr != null) {
        try {
          // EXIF format: "2026:03:08 15:54:03" → "2026-03-08 15:54:03"
          final normalized = dateTimeStr.replaceFirstMapped(
            RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
            (m) => '${m[1]}-${m[2]}-${m[3]}',
          );
          dateTime = DateTime.parse(normalized);
        } catch (e) {
          debugPrint('[$_tag] Failed to parse dateTime "$dateTimeStr": $e');
        }
      }

      final metadata = ImageMetadata(
        latitude: lat,
        longitude: lng,
        dateTime: dateTime,
      );

      debugPrint(
        '[$_tag] Picked: path=$path, lat=$lat, lng=$lng, dateTime=$dateTime',
      );

      return NativePickResult(path: path, metadata: metadata);
    } on PlatformException catch (e) {
      debugPrint('[$_tag] Platform error: ${e.message}');
      return null;
    }
  }
}
