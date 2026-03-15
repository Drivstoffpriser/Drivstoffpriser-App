import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/image_metadata_service.dart';
import '../../../services/price_sign_scanner_service.dart';
import 'confirm_prices_screen.dart';
import 'manual_crop_screen.dart';

const _tag = 'ScanPriceButton';

class ScanPriceButton extends StatefulWidget {
  final ValueChanged<ScanResult> onScanned;

  const ScanPriceButton({super.key, required this.onScanned});

  @override
  State<ScanPriceButton> createState() => _ScanPriceButtonState();
}

const _skipCropTipKey = 'skip_crop_tip';

class _ScanPriceButtonState extends State<ScanPriceButton> {
  bool _isProcessing = false;

  /// Show a one-time tip explaining how to crop the image.
  /// Returns true if the user acknowledged or already dismissed it.
  Future<bool> _showCropTipIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_skipCropTipKey) ?? false) return true;
    if (!mounted) return false;

    bool dontShowAgain = false;

    final acknowledged = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Crop Tip'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'After taking or selecting a photo, you will be asked '
                      'to crop it. The cropped image should ideally contain '
                      'only the fuel station price sign with the logo and '
                      'prices visible.',
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/tips/crop_before.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Icon(Icons.arrow_downward, size: 32),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/tips/crop_after.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Checkbox(
                      value: dontShowAgain,
                      onChanged: (value) {
                        setDialogState(
                            () => dontShowAgain = value ?? false);
                      },
                    ),
                    const Flexible(
                        child: Text("Don't show again")),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (dontShowAgain) {
      await prefs.setBool(_skipCropTipKey, true);
    }

    return acknowledged == true;
  }

  Future<void> _pickAndScan(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    debugPrint('[$_tag] Image source selected: ${source.name}');

    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(source: source);
    } catch (e, stack) {
      debugPrint('[$_tag] ImagePicker error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required')),
      );
      return;
    }

    if (picked == null) {
      debugPrint('[$_tag] User cancelled image picker');
      return;
    }

    debugPrint('[$_tag] Image picked: ${picked.path}');

    // Extract EXIF metadata from the original image (before crop strips it)
    final originalBytes = await picked.readAsBytes();
    final metadata = await ImageMetadataService.extractMetadata(originalBytes);
    debugPrint('[$_tag] EXIF metadata: hasLocation=${metadata.hasLocation}, '
        'hasDateTime=${metadata.hasDateTime}, within24h=${metadata.isTakenWithin24Hours}');

    // Always ask user to crop first
    final file = File(picked.path);
    if (!mounted) return;

    final croppedBytes = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => ManualCropScreen(imageFile: file),
      ),
    );

    if (croppedBytes == null || !mounted) {
      debugPrint('[$_tag] Crop cancelled');
      return;
    }

    // Process the cropped image via Claude API
    setState(() => _isProcessing = true);

    try {
      final scanner = PriceSignScannerService();
      var result = await scanner.scanCroppedImage(croppedBytes);
      // Attach EXIF metadata from original image
      result = result.copyWithMetadata(metadata);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      debugPrint('[$_tag] Scan complete — prices found: ${result.prices.length}');

      // Show confirmation screen with cropped image and editable prices
      if (!mounted) return;
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
        return;
      }

      widget.onScanned(confirmedResult);
    } catch (e, stack) {
      debugPrint('[$_tag] scanCroppedImage() failed: $e\n$stack');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image')),
      );
    }
  }

  Future<void> _showSourcePicker() async {
    final proceed = await _showCropTipIfNeeded();
    if (!proceed || !mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => _pickAndScan(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => _pickAndScan(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : _showSourcePicker,
      icon: _isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt),
      label: Text(_isProcessing ? 'Analyzing...' : 'Scan price sign'),
    );
  }
}
