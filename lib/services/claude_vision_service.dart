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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/fuel_type.dart';
import 'backend_api_client.dart';

const _tag = 'ClaudeVision';

class ClaudeVisionService {
  /// Maximum dimension (width or height) for the compressed image.
  static const int _maxDimension = 800;

  /// JPEG quality for compression (0-100).
  static const int _jpegQuality = 70;

  /// Compress and resize image bytes for the API call.
  ///
  /// Returns JPEG bytes with reduced resolution.
  static Future<Uint8List> compressImage(Uint8List imageBytes) async {
    return compute(_compressInIsolate, imageBytes);
  }

  static Uint8List _compressInIsolate(Uint8List bytes) {
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Failed to decode image');

    // Resize if larger than max dimension
    img.Image resized;
    if (original.width > _maxDimension || original.height > _maxDimension) {
      if (original.width >= original.height) {
        resized = img.copyResize(original, width: _maxDimension);
      } else {
        resized = img.copyResize(original, height: _maxDimension);
      }
    } else {
      resized = original;
    }

    // Encode as JPEG with reduced quality
    return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
  }

  /// Send the image to the backend and extract fuel prices.
  ///
  /// [imageBytes] should be the cropped (and optionally compressed) image.
  /// Compression is applied automatically if not already done.
  static Future<Map<FuelType, double>> extractPrices(
    Uint8List imageBytes,
  ) async {
    // Compress the image
    debugPrint('[$_tag] Compressing image (${imageBytes.length} bytes)...');
    final compressed = await compressImage(imageBytes);
    debugPrint('[$_tag] Compressed to ${compressed.length} bytes');

    final base64Image = base64Encode(compressed);

    debugPrint('[$_tag] Sending request to backend...');
    final stopwatch = Stopwatch()..start();

    final client = BackendApiClient();
    final responseJson = await client.post('/tools/extract-prices', {
      'imageBase64': base64Image,
    });

    stopwatch.stop();
    debugPrint(
      '[$_tag] Backend responded in ${stopwatch.elapsedMilliseconds}ms',
    );

    return _parseResponse(responseJson);
  }

  /// Parse the backend JSON response into a fuel type → price map.
  ///
  /// Expected format: {"diesel": 20.47, "gasoline95": null, "gasoline98": null}
  static Map<FuelType, double> _parseResponse(Map<String, dynamic> json) {
    const keyMap = {
      'diesel': FuelType.diesel,
      'gasoline95': FuelType.petrol95,
      'gasoline98': FuelType.petrol98,
    };

    final prices = <FuelType, double>{};

    for (final entry in keyMap.entries) {
      final value = json[entry.key];
      if (value is num) {
        final price = value.toDouble();
        if (price >= 10.0 && price <= 35.0) {
          prices[entry.value] = price;
          debugPrint('[$_tag] ${entry.key}: $price');
        } else {
          debugPrint('[$_tag] ${entry.key}: $price (out of range, skipped)');
        }
      }
    }

    debugPrint('[$_tag] Extracted ${prices.length} price(s)');
    return prices;
  }
}
