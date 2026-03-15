import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/fuel_type.dart';
import '../../../services/price_sign_scanner_service.dart';

/// Screen that shows the cropped image alongside parsed prices
/// so the user can verify and correct them before confirming.
///
/// Returns a [ScanResult] with the (possibly edited) prices on confirm,
/// or `null` on retake/back.
class ConfirmPricesScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final ScanResult scanResult;

  const ConfirmPricesScreen({
    super.key,
    required this.imageBytes,
    required this.scanResult,
  });

  @override
  State<ConfirmPricesScreen> createState() => _ConfirmPricesScreenState();
}

class _ConfirmPricesScreenState extends State<ConfirmPricesScreen> {
  final Map<FuelType, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final type in FuelType.values) {
      final price = widget.scanResult.prices[type];
      _controllers[type] = TextEditingController(
        text: price != null ? price.toStringAsFixed(2) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  ScanResult _buildResult() {
    final prices = <FuelType, double>{};
    for (final type in FuelType.values) {
      final text = _controllers[type]!.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null && value > 0) {
          prices[type] = value;
        }
      }
    }
    return ScanResult(
      prices: prices,
      rawText: widget.scanResult.rawText,
      cropMethod: widget.scanResult.cropMethod,
    );
  }

  bool get _hasAnyPrice {
    for (final c in _controllers.values) {
      final text = c.text.trim();
      if (text.isNotEmpty && double.tryParse(text) != null) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Prices')),
      body: SafeArea(
        child: Column(
          children: [
            // Cropped image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Editable prices
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Please double check the prices',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final type in FuelType.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              type.displayName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controllers[type],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                hintText: '-',
                                suffixText: 'kr/L',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + bottomPadding),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _hasAnyPrice
                          ? () => Navigator.pop(context, _buildResult())
                          : null,
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
