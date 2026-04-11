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

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Compress and resize image bytes using the `image` package (runs in isolate).
Future<Uint8List> compressImagePlatform(
  Uint8List bytes, {
  int maxDimension = 800,
  int quality = 70,
}) {
  return compute(
    _compress,
    (bytes, maxDimension, quality),
  );
}

Uint8List _compress((Uint8List, int, int) args) {
  final (bytes, maxDimension, quality) = args;
  final original = img.decodeImage(bytes);
  if (original == null) throw Exception('Failed to decode image');

  img.Image resized;
  if (original.width > maxDimension || original.height > maxDimension) {
    if (original.width >= original.height) {
      resized = img.copyResize(original, width: maxDimension);
    } else {
      resized = img.copyResize(original, height: maxDimension);
    }
  } else {
    resized = original;
  }

  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}
