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
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../config/api_config.dart';
import '../models/fuel_type.dart';

const _tag = 'ClaudeVision';

const _systemPrompt = '''
You are a fuel price sign reader for Norwegian fuel stations.
Extract fuel prices from this image of a price sign.

Output ONLY valid JSON in this exact format, nothing else:
{"diesel":null,"petrol_95":null,"petrol_98":null}

Rules:
- Replace null with the price as a number if visible (e.g. 20.47)
- Prices are in NOK per litre, typically between 10.00 and 35.00
- Use decimal point, not comma
- "D" or "Diesel" = diesel
- "95" = petrol_95 (unleaded 95)
- "98" = petrol_98 (unleaded 98)
- If a fuel type is not visible or unreadable, keep it as null
- Output ONLY the raw JSON object, no markdown, no explanation
''';

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

  /// Send the image to Claude API and extract fuel prices.
  ///
  /// [imageBytes] should be the cropped (and optionally compressed) image.
  /// Compression is applied automatically if not already done.
  static Future<Map<FuelType, double>> extractPrices(
    Uint8List imageBytes,
  ) async {
    if (!AnthropicConfig.hasApiKey) {
      throw Exception(
        'Anthropic API key not configured. '
        'Set ANTHROPIC_API_KEY via --dart-define or AnthropicConfig.setApiKey().',
      );
    }

    // Compress the image
    debugPrint('[$_tag] Compressing image (${imageBytes.length} bytes)...');
    final compressed = await compressImage(imageBytes);
    debugPrint('[$_tag] Compressed to ${compressed.length} bytes');

    // Base64 encode
    final base64Image = base64Encode(compressed);

    // Build the API request
    final body = jsonEncode({
      'model': AnthropicConfig.model,
      'max_tokens': AnthropicConfig.maxTokens,
      'system': _systemPrompt.trim(),
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text':
                  'Read the fuel prices from this Norwegian fuel station price sign.',
            },
          ],
        },
      ],
    });

    debugPrint(
      '[$_tag] Sending request to Claude API (${AnthropicConfig.model})...',
    );
    final stopwatch = Stopwatch()..start();

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': AnthropicConfig.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    );

    stopwatch.stop();
    debugPrint(
      '[$_tag] API response: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms',
    );

    if (response.statusCode != 200) {
      debugPrint('[$_tag] API error body: ${response.body}');
      throw Exception(
        'Claude API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    // Parse the response
    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final content = responseJson['content'] as List<dynamic>;
    if (content.isEmpty) {
      throw Exception('Empty response from Claude API');
    }

    final textBlock = content.firstWhere(
      (block) => block['type'] == 'text',
      orElse: () => throw Exception('No text in Claude API response'),
    );
    final rawText = (textBlock['text'] as String).trim();
    debugPrint('[$_tag] Raw response: $rawText');

    return _parseResponse(rawText);
  }

  /// Parse the JSON response from Claude into a fuel type → price map.
  static Map<FuelType, double> _parseResponse(String responseText) {
    // Strip markdown code fences if present
    var text = responseText;
    if (text.startsWith('```')) {
      text = text
          .replaceAll(RegExp(r'^```\w*\n?'), '')
          .replaceAll(RegExp(r'\n?```$'), '');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text.trim()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[$_tag] Failed to parse JSON: $e\nRaw: $text');
      throw Exception('Failed to parse price data from response');
    }

    final prices = <FuelType, double>{};

    const keyMap = {
      'diesel': FuelType.diesel,
      'petrol_95': FuelType.petrol95,
      'petrol_98': FuelType.petrol98,
    };

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
