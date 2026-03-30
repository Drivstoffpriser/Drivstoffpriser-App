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

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/fuel_type.dart';
import 'claude_vision_service.dart';
import 'image_metadata_service.dart';

const _tag = 'PriceSignScanner';

enum CropMethod { none, autoCrop, manualCrop }

class ScanResult {
  final Map<FuelType, double> prices;
  final String rawText;
  final CropMethod cropMethod;
  final bool shouldOfferManualCrop;
  final ImageMetadata? imageMetadata;

  const ScanResult({
    required this.prices,
    required this.rawText,
    this.cropMethod = CropMethod.none,
    this.shouldOfferManualCrop = false,
    this.imageMetadata,
  });

  ScanResult copyWithMetadata(ImageMetadata? metadata) => ScanResult(
    prices: prices,
    rawText: rawText,
    cropMethod: cropMethod,
    shouldOfferManualCrop: shouldOfferManualCrop,
    imageMetadata: metadata,
  );
}

class PriceSignScannerService {
  /// Scan an image file by sending it to Claude Vision API.
  ///
  /// The image should already be cropped by the user before calling this.
  Future<ScanResult> scanImage(File imageFile) async {
    debugPrint('[$_tag] scanImage() called');
    debugPrint('[$_tag]   Image path: ${imageFile.path}');

    final bytes = await imageFile.readAsBytes();
    debugPrint(
      '[$_tag]   File size: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
    );

    try {
      final prices = await ClaudeVisionService.extractPrices(bytes);

      debugPrint('[$_tag] Result: ${_formatFound(prices)}');
      return ScanResult(
        prices: prices,
        rawText: prices.entries
            .map((e) => '${e.key.displayName}: ${e.value}')
            .join('\n'),
        cropMethod: CropMethod.manualCrop,
      );
    } catch (e, stack) {
      debugPrint('[$_tag] Claude API failed: $e\n$stack');
      return const ScanResult(
        prices: {},
        rawText: '',
        shouldOfferManualCrop: false,
      );
    }
  }

  /// Scan a manually-cropped image from raw bytes.
  Future<ScanResult> scanCroppedImage(Uint8List bytes) async {
    debugPrint('[$_tag] scanCroppedImage() called (${bytes.length} bytes)');

    try {
      final prices = await ClaudeVisionService.extractPrices(bytes);

      debugPrint('[$_tag] Cropped result: ${_formatFound(prices)}');
      return ScanResult(
        prices: prices,
        rawText: prices.entries
            .map((e) => '${e.key.displayName}: ${e.value}')
            .join('\n'),
        cropMethod: CropMethod.manualCrop,
      );
    } catch (e, stack) {
      debugPrint('[$_tag] Claude API failed on cropped image: $e\n$stack');
      return const ScanResult(
        prices: {},
        rawText: '',
        cropMethod: CropMethod.manualCrop,
      );
    }
  }

  static String _formatFound(Map<FuelType, double> found) {
    if (found.isEmpty) return '(empty)';
    return found.entries
        .map((e) => '${e.key.displayName}=${e.value}')
        .join(', ');
  }
}
