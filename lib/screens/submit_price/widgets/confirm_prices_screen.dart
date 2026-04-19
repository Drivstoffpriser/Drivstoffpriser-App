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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../l10n/l10n_helper.dart';
import '../../../models/fuel_type.dart';
import '../../../services/price_sign_scanner_service.dart';
import 'price_input_field.dart';

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
        title: Text(
          context.l10n.verifyPrices,
          style: AppTextStyles.title(context),
        ),
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
                    context.l10n.pleaseDoubleCheck,
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
                              type.localizedName(context),
                              style: AppTextStyles.body(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controllers[type],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              inputFormatters: [AutoDecimalFormatter()],
                              style: AppTextStyles.body(context),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                hintText: '-',
                                suffixText: context.l10n.krPerL,
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
                            context.l10n.retake,
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
                              ? AppColors.primaryContainer(context)
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            context.l10n.confirm,
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
