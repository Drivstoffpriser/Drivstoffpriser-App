import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/price_sign_scanner_service.dart';
import 'manual_crop_screen.dart';

const _tag = 'ScanPriceButton';

class ScanPriceButton extends StatefulWidget {
  final ValueChanged<ScanResult> onScanned;

  const ScanPriceButton({super.key, required this.onScanned});

  @override
  State<ScanPriceButton> createState() => _ScanPriceButtonState();
}

class _ScanPriceButtonState extends State<ScanPriceButton> {
  bool _isProcessing = false;

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
    setState(() => _isProcessing = true);

    try {
      final file = File(picked.path);
      debugPrint('[$_tag] File exists: ${file.existsSync()}, size: ${file.existsSync() ? file.lengthSync() : "N/A"} bytes');
      final scanner = PriceSignScannerService();
      final result = await scanner.scanImage(file);

      if (!mounted) return;

      // If few/no prices found, pre-fill what we have and offer manual crop
      if (result.shouldOfferManualCrop) {
        debugPrint('[$_tag] Offering manual crop (${result.prices.length} price(s) so far)');
        setState(() => _isProcessing = false);

        // Pre-fill any prices we already found
        if (result.prices.isNotEmpty) {
          widget.onScanned(result);
        }

        final croppedBytes = await Navigator.push<dynamic>(
          context,
          MaterialPageRoute(
            builder: (_) => ManualCropScreen(imageFile: file),
          ),
        );

        if (croppedBytes == null || !mounted) {
          debugPrint('[$_tag] Manual crop cancelled');
          return;
        }

        setState(() => _isProcessing = true);
        final croppedResult = await scanner.scanCroppedImage(croppedBytes);
        if (!mounted) return;
        setState(() => _isProcessing = false);

        debugPrint('[$_tag] Manual crop scan complete — prices found: ${croppedResult.prices.length}');

        if (croppedResult.rawText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text found in cropped area')),
          );
          return;
        }

        widget.onScanned(croppedResult);
        return;
      }

      setState(() => _isProcessing = false);

      debugPrint('[$_tag] Scan complete — rawText length: ${result.rawText.length}, prices found: ${result.prices.length}');

      if (result.rawText.isEmpty) {
        debugPrint('[$_tag] No text found in image');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found in image')),
        );
        return;
      }

      widget.onScanned(result);
    } catch (e, stack) {
      debugPrint('[$_tag] scanImage() failed: $e\n$stack');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image')),
      );
    }
  }

  void _showSourcePicker() {
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
      label: Text(_isProcessing ? 'Processing...' : 'Scan price sign'),
    );
  }
}
