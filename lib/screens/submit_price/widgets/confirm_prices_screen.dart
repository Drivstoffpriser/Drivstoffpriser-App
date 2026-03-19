import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/fuel_type.dart';
import '../../../services/price_sign_scanner_service.dart';

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
      imageMetadata: widget.scanResult.imageMetadata,
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
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text('Verify Prices', style: AppTextStyles.title(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Please double check the prices',
                    style: AppTextStyles.bodyMedium(context),
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
                              style: AppTextStyles.body(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controllers[type],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              style: AppTextStyles.body(context),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                hintText: '-',
                                suffixText: 'kr/L',
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
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + bottomPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border(context),
                          width: 0.5,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Center(
                          child: Text(
                            'Retake',
                            style: AppTextStyles.bodyMedium(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _hasAnyPrice
                          ? () => Navigator.pop(context, _buildResult())
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _hasAnyPrice
                              ? const Color(0xFF2563EB)
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Confirm',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: _hasAnyPrice
                                  ? Colors.white
                                  : AppColors.textMuted(context),
                            ),
                          ),
                        ),
                      ),
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
