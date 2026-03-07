import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
          SnackBar(content: Text('Crop failed: $cause')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select price sign'),
        actions: [
          TextButton(
            onPressed: _isCropping ? null : _onCrop,
            child: _isCropping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Done'),
          ),
        ],
      ),
      body: _imageBytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Drag to select the area with fuel prices',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
