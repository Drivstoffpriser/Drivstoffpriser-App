import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n_helper.dart';

class ManualCropScreen extends StatefulWidget {
  final File imageFile;

  const ManualCropScreen({super.key, required this.imageFile});

  @override
  State<ManualCropScreen> createState() => _ManualCropScreenState();
}

class _ManualCropScreenState extends State<ManualCropScreen> {
  final _cropController = CropController();
  Uint8List? _imageBytes;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  void _onCrop() {
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.pop(context, croppedImage);
      case CropFailure(:final cause):
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cropFailed(cause.toString()))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.selectPriceSign),
        actions: [
          TextButton(
            onPressed: _isCropping ? null : _onCrop,
            child: _isCropping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.done),
          ),
        ],
      ),
      body: _imageBytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.l10n.dragToSelect,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Crop(
                    image: _imageBytes!,
                    controller: _cropController,
                    onCropped: _onCropped,
                    maskColor: Colors.black54,
                    cornerDotBuilder: (size, edgeAlignment) => DotControl(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
