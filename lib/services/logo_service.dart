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

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class LogoService {
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  /// Pick a logo image from the gallery. Returns the file or null if cancelled.
  static Future<File?> pickLogo() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Resize and compress a logo image to a square PNG (200x200).
  static Future<Uint8List> processLogo(File file) async {
    final bytes = await file.readAsBytes();
    return compute(_processLogoIsolate, bytes);
  }

  static Uint8List _processLogoIsolate(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Crop to square (center crop)
    final size = decoded.width < decoded.height
        ? decoded.width
        : decoded.height;
    final x = (decoded.width - size) ~/ 2;
    final y = (decoded.height - size) ~/ 2;
    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: size,
      height: size,
    );

    // Resize to 200x200
    final resized = img.copyResize(cropped, width: 200, height: 200);

    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Upload a processed logo to Firebase Storage and return the download URL.
  /// Storage path: `brand_logos/{sanitizedBrand}.png`
  static Future<String> uploadLogo({
    required String brand,
    required Uint8List imageBytes,
  }) async {
    final sanitized = brand.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final ref = _storage.ref('brand_logos/$sanitized.png');

    await ref.putData(imageBytes, SettableMetadata(contentType: 'image/png'));

    return ref.getDownloadURL();
  }
}
