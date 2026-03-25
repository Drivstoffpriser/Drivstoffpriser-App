import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../l10n/l10n_helper.dart';
import '../../../services/image_metadata_service.dart';
import '../../../services/native_image_picker_service.dart';
import '../../../services/price_sign_scanner_service.dart';
import 'confirm_prices_screen.dart';
import 'manual_crop_screen.dart';

const _tag = 'ScanPriceButton';

const _skipCropTipKey = 'skip_crop_tip';

class ScanPriceButton extends StatefulWidget {
  final ValueChanged<ScanResult> onScanned;

  const ScanPriceButton({super.key, required this.onScanned});

  @override
  State<ScanPriceButton> createState() => _ScanPriceButtonState();
}

class _ScanPriceButtonState extends State<ScanPriceButton> {
  bool _isProcessing = false;

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
              title: Text(context.l10n.cropTip),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.cropTipBody),
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
                        setDialogState(() => dontShowAgain = value ?? false);
                      },
                    ),
                    Flexible(child: Text(context.l10n.dontShowAgain)),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.l10n.gotIt),
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

  /// Pick from camera using image_picker (camera images aren't GPS-redacted).
  Future<void> _pickFromCamera() async {
    Navigator.pop(context);

    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.camera);
    } catch (e, stack) {
      debugPrint('[$_tag] ImagePicker error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cameraPermissionRequired)),
      );
      return;
    }

    if (picked == null) {
      debugPrint('[$_tag] User cancelled camera');
      return;
    }

    debugPrint('[$_tag] Camera image: ${picked.path}');
    final originalBytes = await picked.readAsBytes();
    final metadata = await ImageMetadataService.extractMetadata(originalBytes);
    debugPrint(
      '[$_tag] EXIF metadata: hasLocation=${metadata.hasLocation}, '
      'hasDateTime=${metadata.hasDateTime}, within24h=${metadata.isTakenWithin24Hours}',
    );

    await _cropAndScan(File(picked.path), metadata);
  }

  /// Pick from gallery using native method channel to preserve GPS EXIF data.
  Future<void> _pickFromGallery() async {
    Navigator.pop(context);

    final pickResult = await NativeImagePickerService.pickImageFromGallery();
    if (pickResult == null) {
      debugPrint('[$_tag] User cancelled gallery');
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

  /// Common flow: crop → scan → confirm → callback.
  Future<void> _cropAndScan(File imageFile, ImageMetadata metadata) async {
    if (!mounted) return;

    final croppedBytes = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => ManualCropScreen(imageFile: imageFile)),
    );

    if (croppedBytes == null || !mounted) {
      debugPrint('[$_tag] Crop cancelled');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final scanner = PriceSignScannerService();
      var result = await scanner.scanCroppedImage(croppedBytes);
      result = result.copyWithMetadata(metadata);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      debugPrint(
        '[$_tag] Scan complete — prices found: ${result.prices.length}',
      );

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
        SnackBar(content: Text(context.l10n.failedToProcessImage)),
      );
    }
  }

  Future<void> _showSourcePicker() async {
    final proceed = await _showCropTipIfNeeded();
    if (!proceed || !mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.textPrimary(context),
                ),
                title: Text(
                  context.l10n.takePhoto,
                  style: AppTextStyles.body(context),
                ),
                onTap: _pickFromCamera,
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.textPrimary(context),
                ),
                title: Text(
                  context.l10n.chooseFromGallery,
                  style: AppTextStyles.body(context),
                ),
                onTap: _pickFromGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isProcessing ? null : _showSourcePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.camera_alt_outlined,
                size: 20,
                color: AppColors.textPrimary(context),
              ),
            const SizedBox(width: 8),
            Text(
              _isProcessing
                  ? context.l10n.analyzing
                  : context.l10n.scanPriceSign,
              style: AppTextStyles.bodyMedium(context),
            ),
          ],
        ),
      ),
    );
  }
}
