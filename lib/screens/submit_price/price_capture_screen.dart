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
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n_helper.dart';
import '../../models/station.dart';
import '../../services/image_metadata_service.dart';
import '../../services/native_image_picker_service.dart';
import '../../services/price_sign_scanner_service.dart';
import 'submit_price_screen.dart';
import 'widgets/camera_with_stencil_screen.dart';
import 'widgets/confirm_prices_screen.dart';
import 'widgets/manual_crop_screen.dart';

const _tag = 'PriceCapture';

/// Orchestrator screen that opens the camera first, then routes to the
/// appropriate flow (capture, gallery, or manual entry).
class PriceCaptureScreen extends StatefulWidget {
  final Station station;

  const PriceCaptureScreen({super.key, required this.station});

  @override
  State<PriceCaptureScreen> createState() => _PriceCaptureScreenState();
}

class _PriceCaptureScreenState extends State<PriceCaptureScreen> {
  bool _launched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_launched) {
      _launched = true;
      // Show camera on the next frame so Navigator is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
    }
  }

  Future<void> _openCamera() async {
    if (!mounted) return;

    final result = await CameraWithStencilScreen.open(context);

    if (!mounted) return;

    if (result is XFile) {
      await _handleCapture(result);
    } else if (result == CameraAction.gallery) {
      await _handleGallery();
    } else if (result == CameraAction.manual) {
      _goToForm();
    } else {
      // User cancelled — go back.
      Navigator.pop(context);
    }
  }

  Future<void> _handleCapture(XFile picked) async {
    debugPrint('[$_tag] Camera image: ${picked.path}');
    final originalBytes = await picked.readAsBytes();
    final metadata = await ImageMetadataService.extractMetadata(originalBytes);
    debugPrint(
      '[$_tag] EXIF metadata: hasLocation=${metadata.hasLocation}, '
      'hasDateTime=${metadata.hasDateTime}, '
      'within24h=${metadata.isTakenWithin24Hours}',
    );

    await _cropAndScan(File(picked.path), metadata);
  }

  Future<void> _handleGallery() async {
    final pickResult = await NativeImagePickerService.pickImageFromGallery();
    if (pickResult == null) {
      debugPrint('[$_tag] User cancelled gallery');
      if (!mounted) return;
      // Re-open camera so user can try again.
      _openCamera();
      return;
    }

    debugPrint('[$_tag] Gallery image: ${pickResult.path}');
    debugPrint(
      '[$_tag] Native EXIF: hasLocation=${pickResult.metadata.hasLocation}, '
      'hasDateTime=${pickResult.metadata.hasDateTime}, '
      'within24h=${pickResult.metadata.isTakenWithin24Hours}',
    );

    await _cropAndScan(File(pickResult.path), pickResult.metadata);
  }

  Future<void> _cropAndScan(File imageFile, ImageMetadata metadata) async {
    if (!mounted) return;

    final croppedBytes = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => ManualCropScreen(imageFile: imageFile)),
    );

    if (croppedBytes == null || !mounted) {
      debugPrint('[$_tag] Crop cancelled');
      _openCamera();
      return;
    }

    try {
      final scanner = PriceSignScannerService();
      var result = await scanner.scanCroppedImage(croppedBytes);
      result = result.copyWithMetadata(metadata);
      if (!mounted) return;

      debugPrint(
        '[$_tag] Scan complete — prices found: ${result.prices.length}',
      );

      final confirmedResult = await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmPricesScreen(
            imageBytes: croppedBytes as Uint8List,
            scanResult: result,
          ),
        ),
      );

      if (confirmedResult == null || !mounted) {
        debugPrint('[$_tag] User did not confirm prices');
        _openCamera();
        return;
      }

      _goToForm(scanResult: confirmedResult);
    } catch (e, stack) {
      debugPrint('[$_tag] scanCroppedImage() failed: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.failedToProcessImage)),
      );
      _openCamera();
    }
  }

  void _goToForm({ScanResult? scanResult}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitPriceScreen(
          station: widget.station,
          initialScanResult: scanResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This screen is transparent — the camera or subsequent screens
    // are pushed on top. Show a black background as fallback.
    return const Scaffold(backgroundColor: Colors.black);
  }
}
