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

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n_helper.dart';

class CameraWithStencilScreen extends StatefulWidget {
  const CameraWithStencilScreen({super.key});

  @override
  State<CameraWithStencilScreen> createState() =>
      _CameraWithStencilScreenState();
}

class _CameraWithStencilScreenState extends State<CameraWithStencilScreen> {
  CameraController? _controller;
  bool _isCapturing = false;
  String? _error;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  static const _zoomPresets = [1.0, 2.0];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No cameras available');
        return;
      }

      // Prefer the back camera.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();

      setState(() {
        _controller = controller;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _setZoom(double zoom) async {
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    await _controller?.setZoomLevel(clamped);
    setState(() => _currentZoom = clamped);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.failedToProcessImage)),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          : _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    return GestureDetector(
      onScaleStart: (_) => _baseZoom = _currentZoom,
      onScaleUpdate: (details) => _setZoom(_baseZoom * details.scale),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview.
          Center(child: CameraPreview(_controller!)),

          // Stencil overlay.
          Center(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/tips/sign_stencil2.png',
                width: MediaQuery.of(context).size.width * 0.5,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Top bar with back button.
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Bottom controls: zoom presets + capture button.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom preset buttons.
                    _buildZoomPresets(),
                    const SizedBox(height: 20),
                    // Capture button.
                    GestureDetector(
                      onTap: _isCapturing ? null : _capture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isAtPreset =>
      _zoomPresets.any((p) => (_currentZoom - p).abs() < 0.1);

  Widget _buildZoomPresets() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current zoom indicator (shown when not at a preset).
        AnimatedOpacity(
          opacity: _isAtPreset ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_currentZoom.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Preset buttons.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _zoomPresets.where((z) => z <= _maxZoom).map((preset) {
            final isActive = (_currentZoom - preset).abs() < 0.1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => _setZoom(preset),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white.withAlpha(200)
                        : Colors.black.withAlpha(120),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${preset.toStringAsFixed(0)}x',
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
