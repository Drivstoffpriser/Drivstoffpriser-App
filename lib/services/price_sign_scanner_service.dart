import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../models/fuel_type.dart';

const _tag = 'PriceSignScanner';

enum CropMethod { none, autoCrop, manualCrop }

class ScanResult {
  final Map<FuelType, double> prices;
  final String rawText;
  final CropMethod cropMethod;
  final bool shouldOfferManualCrop;

  const ScanResult({
    required this.prices,
    required this.rawText,
    this.cropMethod = CropMethod.none,
    this.shouldOfferManualCrop = false,
  });
}

class PriceSignScannerService {
  static final _pricePattern = RegExp(r'\b(\d{1,2}\.\d{1,2})\b');
  static final _dieselPattern = RegExp(r'\b[Dd](iesel)?\b');
  static final _petrol95Pattern = RegExp(r'\b95\b');
  static final _petrol98Pattern = RegExp(r'\b98\b');

  /// Pattern for 3-4 digit sequences without a decimal (e.g. "2047", "1979").
  static final _bareDigitsPattern = RegExp(r'\b(\d{3,4})\b');

  /// Common LED 7-segment OCR misreads: letter → digit.
  static final _ledCharReplacements = RegExp(r'(?<=\d)[sS]|[sS](?=\d)');

  /// Minimum and maximum plausible fuel price in NOK per litre.
  static const _minPrice = 10.0;
  static const _maxPrice = 35.0;

  /// Minimum region size in pixels to attempt auto-crop.
  static const _minRegionSize = 10;

  /// Run ML Kit text recognition on [imageFile] and parse fuel prices.
  ///
  /// Pipeline:
  /// 1. Detection pass on full image — find fuel-related text blocks
  /// 2. If region found → auto-crop to sign area → dual-pass OCR on crop
  /// 3. If no region → return results with shouldOfferManualCrop flag
  Future<ScanResult> scanImage(File imageFile) async {
    final fileSize = await imageFile.length();
    debugPrint('[$_tag] scanImage() called');
    debugPrint('[$_tag]   Image path: ${imageFile.path}');
    debugPrint('[$_tag]   File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
    debugPrint('[$_tag]   File exists: ${imageFile.existsSync()}');

    // --- Stage 1: Detection pass ---
    Rect? signRegion;
    Map<FuelType, double> detectionPrices = {};
    String detectionRawText = '';

    try {
      final detection = await _runDetectionPass(imageFile);
      signRegion = detection.region;
      detectionPrices = detection.prices;
      detectionRawText = detection.rawText;
      debugPrint('[$_tag] Detection pass found region: $signRegion, prices: ${_formatFound(detectionPrices)}');
    } catch (e) {
      debugPrint('[$_tag] Detection pass failed: $e — falling through to full-image OCR');
    }

    // --- Stage 2: Auto-crop if region found ---
    if (signRegion != null &&
        signRegion.width >= _minRegionSize &&
        signRegion.height >= _minRegionSize) {
      debugPrint('[$_tag] Auto-cropping to sign region: $signRegion');
      File? croppedFile;
      try {
        croppedFile = await _cropImage(imageFile, signRegion);
        final croppedResult = await _runDualPassOcr(croppedFile);

        // Merge: cropped results take priority, fill gaps from detection
        final merged = Map<FuelType, double>.from(croppedResult.prices);
        for (final entry in detectionPrices.entries) {
          merged.putIfAbsent(entry.key, () => entry.value);
        }

        final rawTexts = [croppedResult.rawText, detectionRawText].join('\n---\n');

        debugPrint('[$_tag] Auto-crop merged result: ${_formatFound(merged)}');
        return ScanResult(
          prices: merged,
          rawText: rawTexts,
          cropMethod: CropMethod.autoCrop,
          shouldOfferManualCrop: merged.length <= 1,
        );
      } catch (e) {
        debugPrint('[$_tag] Auto-crop failed: $e — falling through to full-image OCR');
      } finally {
        croppedFile?.deleteSync();
      }
    }

    // --- Stage 3: No region found or crop failed — full-image dual-pass ---
    if (detectionPrices.isNotEmpty) {
      // We got prices from the detection pass but no crop region — use them
      debugPrint('[$_tag] No crop region, but detection found prices: ${_formatFound(detectionPrices)}');
      final fullResult = await _runDualPassOcr(imageFile);

      final merged = Map<FuelType, double>.from(fullResult.prices);
      for (final entry in detectionPrices.entries) {
        merged.putIfAbsent(entry.key, () => entry.value);
      }

      final rawTexts = [fullResult.rawText, detectionRawText].join('\n---\n');
      return ScanResult(
        prices: merged,
        rawText: rawTexts,
        shouldOfferManualCrop: merged.length <= 1,
      );
    }

    // No region and no prices from detection — run full dual-pass anyway
    final fullResult = await _runDualPassOcr(imageFile);
    if (fullResult.prices.length <= 1) {
      debugPrint('[$_tag] Found ${fullResult.prices.length} price(s) — offering manual crop');
      return ScanResult(
        prices: fullResult.prices,
        rawText: fullResult.rawText,
        shouldOfferManualCrop: true,
      );
    }

    return fullResult;
  }

  /// Scan a manually-cropped image from raw bytes.
  Future<ScanResult> scanCroppedImage(Uint8List bytes) async {
    debugPrint('[$_tag] scanCroppedImage() called (${bytes.length} bytes)');
    final tempPath = '${Directory.systemTemp.path}/manual_crop_${DateTime.now().millisecondsSinceEpoch}.png';
    final tempFile = File(tempPath);
    try {
      await tempFile.writeAsBytes(bytes);
      final result = await _runDualPassOcr(tempFile);
      return ScanResult(
        prices: result.prices,
        rawText: result.rawText,
        cropMethod: CropMethod.manualCrop,
      );
    } finally {
      if (tempFile.existsSync()) tempFile.deleteSync();
    }
  }

  /// Run dual-pass OCR (LED preprocessing + original) and merge results.
  Future<ScanResult> _runDualPassOcr(File imageFile) async {
    // --- Pass 1: Red channel preprocessing for LED signs ---
    debugPrint('[$_tag] === Dual-pass OCR: Pass 1 (LED) ===');
    File? preprocessedFile;
    ScanResult? ledResult;
    try {
      preprocessedFile = await _preprocessForLed(imageFile);
      ledResult = await _runOcr(preprocessedFile);
      debugPrint('[$_tag] LED pass found ${ledResult.prices.length} price(s): ${_formatFound(ledResult.prices)}');
    } catch (e) {
      debugPrint('[$_tag] LED preprocessing failed: $e');
    } finally {
      preprocessedFile?.deleteSync();
    }

    // --- Pass 2: Original image ---
    debugPrint('[$_tag] === Dual-pass OCR: Pass 2 (original) ===');
    final originalResult = await _runOcr(imageFile);
    debugPrint('[$_tag] Original pass found ${originalResult.prices.length} price(s): ${_formatFound(originalResult.prices)}');

    // Merge: start with whichever found more, fill gaps from the other.
    final ScanResult primary;
    final ScanResult secondary;
    if ((ledResult?.prices.length ?? 0) >= originalResult.prices.length) {
      primary = ledResult ?? originalResult;
      secondary = originalResult;
    } else {
      primary = originalResult;
      secondary = ledResult ?? originalResult;
    }

    final merged = Map<FuelType, double>.from(primary.prices);
    for (final entry in secondary.prices.entries) {
      merged.putIfAbsent(entry.key, () => entry.value);
    }

    debugPrint('[$_tag] Dual-pass merged result: ${_formatFound(merged)}');

    final rawTexts = [
      if (ledResult != null) ledResult.rawText,
      originalResult.rawText,
    ].join('\n---\n');

    return ScanResult(prices: merged, rawText: rawTexts);
  }

  /// Run detection pass: OCR the full image, find fuel-related text blocks,
  /// compute the union bounding box.
  Future<_DetectionResult> _runDetectionPass(File imageFile) async {
    debugPrint('[$_tag] === Detection pass ===');
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    try {
      final recognized = await textRecognizer.processImage(inputImage);
      debugPrint('[$_tag] Detection: ${recognized.blocks.length} block(s)');

      Rect? region;
      final allFuelText = StringBuffer();

      for (final block in recognized.blocks) {
        if (_blockContainsFuelContent(block)) {
          debugPrint('[$_tag] Detection: fuel block "${block.text}" at ${block.boundingBox}');
          allFuelText.writeln(block.text);
          if (region == null) {
            region = block.boundingBox;
          } else {
            region = region.expandToInclude(block.boundingBox);
          }
        }
      }

      final prices = allFuelText.isNotEmpty
          ? parseRecognizedText(allFuelText.toString())
          : <FuelType, double>{};

      return _DetectionResult(
        region: region,
        prices: prices,
        rawText: recognized.text,
      );
    } finally {
      textRecognizer.close();
    }
  }

  /// Check if a text block contains fuel-related content (label or price).
  static bool _blockContainsFuelContent(TextBlock block) {
    final text = block.text;
    if (_dieselPattern.hasMatch(text)) return true;
    if (_petrol95Pattern.hasMatch(text)) return true;
    if (_petrol98Pattern.hasMatch(text)) return true;

    // Check for plausible prices
    final normalized = _normalizeLedText(text.replaceAll(',', '.'));
    if (_extractPrice(normalized) != null) return true;
    if (_bareDigitsPattern.hasMatch(text)) {
      // Check if bare digits would normalize to a valid price
      final withDecimal = _normalizeLedText(text);
      if (_extractPrice(withDecimal) != null) return true;
    }

    return false;
  }

  /// Crop the image to the given region with padding.
  Future<File> _cropImage(File imageFile, Rect region, {double padding = 0.20}) async {
    debugPrint('[$_tag] Cropping image to region: $region (padding: ${(padding * 100).toInt()}%)');
    final stopwatch = Stopwatch()..start();

    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Failed to decode image for cropping');

    final padX = (region.width * padding).round();
    final padY = (region.height * padding).round();

    final x = (region.left.round() - padX).clamp(0, original.width - 1);
    final y = (region.top.round() - padY).clamp(0, original.height - 1);
    final right = (region.right.round() + padX).clamp(x + 1, original.width);
    final bottom = (region.bottom.round() + padY).clamp(y + 1, original.height);
    final w = right - x;
    final h = bottom - y;

    debugPrint('[$_tag]   Crop rect: x=$x, y=$y, w=$w, h=$h (image: ${original.width}x${original.height})');

    final cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
    final encoded = img.encodePng(cropped);
    final tempPath = '${imageFile.parent.path}/auto_cropped_${DateTime.now().millisecondsSinceEpoch}.png';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(encoded);

    stopwatch.stop();
    debugPrint('[$_tag]   Crop took ${stopwatch.elapsedMilliseconds}ms → ${tempFile.path}');
    return tempFile;
  }

  /// Run ML Kit OCR on a single image file and return parsed results.
  Future<ScanResult> _runOcr(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    try {
      final stopwatch = Stopwatch()..start();
      final recognized = await textRecognizer.processImage(inputImage);
      stopwatch.stop();

      debugPrint('[$_tag] ML Kit processing took ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('[$_tag] Recognized ${recognized.blocks.length} text block(s)');

      for (int b = 0; b < recognized.blocks.length; b++) {
        final block = recognized.blocks[b];
        debugPrint('[$_tag] --- Block $b: "${block.text}"');
        debugPrint('[$_tag]     Bounding box: ${block.boundingBox}');
        debugPrint('[$_tag]     Languages: ${block.recognizedLanguages.join(", ")}');
        for (int l = 0; l < block.lines.length; l++) {
          final line = block.lines[l];
          debugPrint('[$_tag]     Line $l: "${line.text}"');
          debugPrint('[$_tag]       Bounding box: ${line.boundingBox}');
          debugPrint('[$_tag]       Confidence: ${line.confidence?.toStringAsFixed(2) ?? "n/a"}');
          for (int e = 0; e < line.elements.length; e++) {
            final element = line.elements[e];
            debugPrint('[$_tag]       Element $e: "${element.text}" (confidence: ${element.confidence?.toStringAsFixed(2) ?? "n/a"})');
          }
        }
      }

      final rawText = recognized.text;
      debugPrint('[$_tag] Full raw text:\n---\n$rawText\n---');

      final prices = parseRecognizedText(rawText);
      return ScanResult(prices: prices, rawText: rawText);
    } finally {
      textRecognizer.close();
    }
  }

  /// Preprocess image to isolate red LED digits.
  ///
  /// LED price signs use dot-matrix displays with individual LED dots.
  /// Processing pipeline:
  /// 1. Downscale to ~1024px wide — partially merges LED dots via averaging
  /// 2. Gaussian blur — further merges remaining dot gaps into solid strokes
  /// 3. Red channel isolation — keep pixels where red dominates green/blue
  /// 4. Blur + re-threshold — fill remaining small gaps in digit strokes
  Future<File> _preprocessForLed(File imageFile) async {
    debugPrint('[$_tag] Preprocessing: LED red-channel isolation...');
    final stopwatch = Stopwatch()..start();

    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Failed to decode image');

    debugPrint('[$_tag]   Original size: ${original.width}x${original.height}');

    // Step 1: Downscale to merge LED dots via pixel averaging.
    const targetWidth = 1024;
    final scaled = original.width > targetWidth
        ? img.copyResize(original, width: targetWidth, interpolation: img.Interpolation.average)
        : original;
    debugPrint('[$_tag]   After downscale: ${scaled.width}x${scaled.height}');

    // Step 2: Gaussian blur to smooth remaining LED dot patterns.
    final blurred = img.gaussianBlur(scaled, radius: 3);

    // Step 3: Red channel isolation — pixels where red dominates → black digit.
    final binary = img.Image(width: blurred.width, height: blurred.height);
    for (int y = 0; y < blurred.height; y++) {
      for (int x = 0; x < blurred.width; x++) {
        final pixel = blurred.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // "Redness" = how much red exceeds the average of green and blue.
        final redness = r - ((g + b) ~/ 2);
        final isRedLed = r > 80 && redness > 30;

        binary.setPixelRgb(x, y,
          isRedLed ? 0 : 255,
          isRedLed ? 0 : 255,
          isRedLed ? 0 : 255,
        );
      }
    }

    // Step 4: Blur the binary image and re-threshold to fill small gaps
    // between LED dots that survived the earlier processing.
    final smoothed = img.gaussianBlur(binary, radius: 2);
    for (int y = 0; y < smoothed.height; y++) {
      for (int x = 0; x < smoothed.width; x++) {
        final lum = smoothed.getPixel(x, y).r.toInt();
        // Threshold below 220 → digit (black), else → background (white).
        // Using 220 instead of 128 aggressively expands digit regions.
        final val = lum < 220 ? 0 : 255;
        smoothed.setPixelRgb(x, y, val, val, val);
      }
    }

    final encoded = img.encodePng(smoothed);
    final tempPath = '${imageFile.parent.path}/led_preprocessed.png';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(encoded);

    stopwatch.stop();
    debugPrint('[$_tag]   Preprocessing took ${stopwatch.elapsedMilliseconds}ms → ${tempFile.path}');
    return tempFile;
  }

  /// Parse recognized text into a map of fuel type → price.
  ///
  /// This is a pure function, separated for unit testing.
  static Map<FuelType, double> parseRecognizedText(String text) {
    debugPrint('[$_tag] parseRecognizedText() called');

    // Normalize Norwegian decimal separators (comma → dot).
    final commasFixed = text.replaceAll(',', '.');

    // Fix LED 7-segment OCR misreads and recover missing decimals.
    final normalized = _normalizeLedText(commasFixed);
    if (normalized != commasFixed) {
      debugPrint('[$_tag] LED normalization: "$commasFixed" → "$normalized"');
    }

    final lines = normalized.split('\n').map((l) => l.trim()).toList();

    debugPrint('[$_tag] Normalized ${lines.length} line(s):');
    for (int i = 0; i < lines.length; i++) {
      final price = _extractPrice(lines[i]);
      final hasD = _dieselPattern.hasMatch(lines[i]);
      final has95 = _petrol95Pattern.hasMatch(lines[i]);
      final has98 = _petrol98Pattern.hasMatch(lines[i]);
      final labels = [
        if (hasD) 'diesel',
        if (has95) '95',
        if (has98) '98',
      ];
      debugPrint('[$_tag]   [$i] "${lines[i]}" → price: ${price ?? "none"}, labels: ${labels.isEmpty ? "none" : labels.join(", ")}');
    }

    final found = <FuelType, double>{};

    // Pass 1: look for fuel label + price on the same line.
    debugPrint('[$_tag] Pass 1 (same-line matching):');
    for (final line in lines) {
      _tryExtract(line, found);
    }
    debugPrint('[$_tag]   After pass 1: ${_formatFound(found)}');

    // Pass 2: for unfound types, check adjacent lines (label on line N, price on N±1).
    // Track which line indices have been consumed to avoid double-claiming.
    final fuelTypes = {
      FuelType.diesel: _dieselPattern,
      FuelType.petrol95: _petrol95Pattern,
      FuelType.petrol98: _petrol98Pattern,
    };
    final consumedLines = <int>{};

    debugPrint('[$_tag] Pass 2 (adjacent-line matching):');
    for (final entry in fuelTypes.entries) {
      if (found.containsKey(entry.key)) {
        debugPrint('[$_tag]   ${entry.key.displayName}: already found in pass 1, skipping');
        continue;
      }

      for (int i = 0; i < lines.length; i++) {
        if (!entry.value.hasMatch(lines[i])) continue;
        debugPrint('[$_tag]   ${entry.key.displayName}: label match on line [$i] "${lines[i]}"');

        // Prefer line below (i+1) then above (i-1) to match top-to-bottom sign layout.
        for (final adj in [i + 1, i - 1]) {
          if (adj < 0 || adj >= lines.length) continue;
          if (consumedLines.contains(adj)) {
            debugPrint('[$_tag]     line [$adj] "${lines[adj]}" — already consumed, skipping');
            continue;
          }
          final price = _extractPrice(lines[adj]);
          debugPrint('[$_tag]     line [$adj] "${lines[adj]}" → price: ${price ?? "none"}');
          if (price != null) {
            found[entry.key] = price;
            consumedLines.add(adj);
            break;
          }
        }
        if (found.containsKey(entry.key)) break;
      }
    }

    debugPrint('[$_tag] Final result: ${_formatFound(found)}');
    return found;
  }

  static String _formatFound(Map<FuelType, double> found) {
    if (found.isEmpty) return '(empty)';
    return found.entries.map((e) => '${e.key.displayName}=${e.value}').join(', ');
  }

  /// Try to extract fuel label + price from a single line.
  static void _tryExtract(String line, Map<FuelType, double> found) {
    final price = _extractPrice(line);
    if (price == null) return;

    if (!found.containsKey(FuelType.diesel) && _dieselPattern.hasMatch(line)) {
      found[FuelType.diesel] = price;
    }
    if (!found.containsKey(FuelType.petrol95) &&
        _petrol95Pattern.hasMatch(line)) {
      found[FuelType.petrol95] = price;
    }
    if (!found.containsKey(FuelType.petrol98) &&
        _petrol98Pattern.hasMatch(line)) {
      found[FuelType.petrol98] = price;
    }
  }

  /// Normalize text from LED 7-segment displays.
  ///
  /// Fixes common OCR misreads and recovers missing decimal points.
  static String _normalizeLedText(String text) {
    var result = text;

    // Fix common LED misreads: 's'/'S' next to digits → '5'
    result = result.replaceAllMapped(
      _ledCharReplacements,
      (m) => '5',
    );

    // Recover missing decimal points in bare digit sequences.
    // e.g. "2047" → "20.47", "1979" → "19.79"
    result = result.replaceAllMapped(_bareDigitsPattern, (m) {
      final digits = m.group(1)!;
      // Try inserting a decimal 2 digits from the left: "2047" → "20.47"
      if (digits.length == 4) {
        final candidate = '${digits.substring(0, 2)}.${digits.substring(2)}';
        final value = double.tryParse(candidate);
        if (value != null && value >= _minPrice && value <= _maxPrice) {
          return candidate;
        }
      }
      // Try 3-digit: "207" → "20.7"
      if (digits.length == 3) {
        final candidate = '${digits.substring(0, 2)}.${digits.substring(2)}';
        final value = double.tryParse(candidate);
        if (value != null && value >= _minPrice && value <= _maxPrice) {
          return candidate;
        }
      }
      return digits; // leave unchanged
    });

    return result;
  }

  /// Extract the first plausible fuel price from [text].
  static double? _extractPrice(String text) {
    for (final match in _pricePattern.allMatches(text)) {
      final value = double.tryParse(match.group(1)!);
      if (value != null && value >= _minPrice && value <= _maxPrice) {
        return value;
      }
    }
    return null;
  }
}

/// Internal result type for the detection pass.
class _DetectionResult {
  final Rect? region;
  final Map<FuelType, double> prices;
  final String rawText;

  const _DetectionResult({
    required this.region,
    required this.prices,
    required this.rawText,
  });
}
