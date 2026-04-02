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
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

const _tag = 'AutoCropService';

/// Price pattern: 2 digits, separator, 2 digits (e.g. "19.99", "24,06").
final _pricePattern = RegExp(r'\d{2}[.,]\d{2}');

/// 4-digit numbers that could be LED prices without decimal (e.g. "2606" = 26.06).
/// Valid range: 1000–3500 (i.e. 10.00–35.00 NOK).
final _ledPricePattern = RegExp(r'^\d{4}$');

/// Fuel-related keywords commonly found on Norwegian price signs.
final _fuelKeywords = RegExp(
  r'^(D|Diesel|diesel|95|98|Bensin|bensin|Fra|fra|Blyfri|blyfri)$',
  caseSensitive: false,
);

class AutoCropService {
  /// Detect price-sign region in the image at [filePath].
  ///
  /// Returns a [Rect] in image coordinates encompassing detected price text,
  /// with padding applied. Returns null if no prices are found.
  static Future<Rect?> detectPriceRegion(String filePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognised = await recognizer.processImage(inputImage);

      debugPrint('[$_tag] Total blocks: ${recognised.blocks.length}');

      final signBoxes = <Rect>[];

      for (final block in recognised.blocks) {
        debugPrint('[$_tag] Block: "${block.text}" at ${block.boundingBox}');

        // If any line in the block contains a fuel keyword, price pattern,
        // or LED-style price number, include the entire block.
        var blockMatched = false;
        for (final line in block.lines) {
          debugPrint('[$_tag]   Line: "${line.text}" at ${line.boundingBox}');

          if (_pricePattern.hasMatch(line.text)) {
            debugPrint('[$_tag]     -> price match');
            blockMatched = true;
            continue;
          }

          // Check for 4-digit LED prices (e.g. "2606" = 26.06 NOK).
          for (final element in line.elements) {
            final text = element.text;
            if (_ledPricePattern.hasMatch(text)) {
              final value = int.tryParse(text);
              if (value != null && value >= 1000 && value <= 3500) {
                debugPrint('[$_tag]     -> LED price "$text" '
                    'at ${element.boundingBox}');
                blockMatched = true;
              }
            }
            if (_fuelKeywords.hasMatch(text)) {
              debugPrint('[$_tag]     -> keyword "$text" '
                  'at ${element.boundingBox}');
              blockMatched = true;
            }
          }
        }

        if (blockMatched) {
          debugPrint('[$_tag]   -> using full block: ${block.boundingBox}');
          signBoxes.add(block.boundingBox);
        }
      }

      if (signBoxes.isEmpty) {
        debugPrint('[$_tag] No sign-related text detected');
        return null;
      }

      // Merge all matching bounding boxes into one.
      var merged = signBoxes.first;
      for (final box in signBoxes.skip(1)) {
        merged = merged.expandToInclude(box);
      }

      // Get image dimensions for clamping.
      final imageSize = await _getImageSize(filePath);

      // Ensure the crop region meets a minimum size (20% of image dimensions).
      // Small detections like a lone "95" label need expanding to be useful.
      final minW = imageSize.width * 0.20;
      final minH = imageSize.height * 0.20;

      // Add generous padding (50%) to capture surrounding context.
      final padX = merged.width * 0.5;
      final padY = merged.height * 0.5;
      var padded = Rect.fromLTRB(
        merged.left - padX,
        merged.top - padY,
        merged.right + padX,
        merged.bottom + padY,
      );

      // Expand to minimum size if needed, centered on the detected area.
      if (padded.width < minW || padded.height < minH) {
        final cx = padded.center.dx;
        final cy = padded.center.dy;
        final halfW = (padded.width < minW ? minW : padded.width) / 2;
        final halfH = (padded.height < minH ? minH : padded.height) / 2;
        padded = Rect.fromLTRB(cx - halfW, cy - halfH, cx + halfW, cy + halfH);
      }

      // Clamp to image bounds.
      padded = Rect.fromLTRB(
        padded.left.clamp(0, imageSize.width),
        padded.top.clamp(0, imageSize.height),
        padded.right.clamp(0, imageSize.width),
        padded.bottom.clamp(0, imageSize.height),
      );

      debugPrint('[$_tag] Detected region: $padded '
          '(${signBoxes.length} matching blocks, '
          'image: ${imageSize.width.toInt()}x${imageSize.height.toInt()})');
      return padded;
    } catch (e, stack) {
      debugPrint('[$_tag] Text recognition failed: $e\n$stack');
      return null;
    } finally {
      await recognizer.close();
    }
  }

  /// Read JPEG/PNG header to get image dimensions without full decode.
  static Future<Size> _getImageSize(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final decoder = img.findDecoderForData(bytes);
      if (decoder != null) {
        final info = decoder.startDecode(bytes);
        if (info != null) {
          return Size(info.width.toDouble(), info.height.toDouble());
        }
      }
    } catch (e) {
      debugPrint('[$_tag] Failed to read image size: $e');
    }
    // Fallback: large values so clamping has no effect.
    return const Size(99999, 99999);
  }
}
