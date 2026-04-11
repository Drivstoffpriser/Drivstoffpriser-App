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

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Compress and resize image bytes using the browser's native Canvas API.
Future<Uint8List> compressImagePlatform(
  Uint8List bytes, {
  int maxDimension = 800,
  int quality = 70,
}) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    // Load image via an <img> element.
    final imgEl = html.ImageElement()..src = url;
    await imgEl.onLoad.first;

    // Calculate target dimensions.
    var width = imgEl.naturalWidth;
    var height = imgEl.naturalHeight;
    if (width > maxDimension || height > maxDimension) {
      if (width >= height) {
        height = (height * maxDimension / width).round();
        width = maxDimension;
      } else {
        width = (width * maxDimension / height).round();
        height = maxDimension;
      }
    }

    // Draw scaled image onto a canvas.
    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(imgEl, 0, 0, width, height);

    // Export as JPEG data URL and decode the base64 portion.
    final dataUrl = canvas.toDataUrl('image/jpeg', quality / 100);
    final base64Data = dataUrl.split(',')[1];
    return Uint8List.fromList(base64Decode(base64Data));
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
