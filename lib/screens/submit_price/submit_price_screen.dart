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
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/fuel_type.dart';
import '../../models/station.dart';
import '../../providers/location_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/cooldown_prefs_service.dart';
import '../../services/distance_service.dart';
import '../../services/image_metadata_service.dart';
import '../../services/price_sign_scanner_service.dart';
import '../../widgets/brand_logo.dart';
import 'widgets/price_input_field.dart';
import 'widgets/scan_price_button.dart';

class SubmitPriceScreen extends StatefulWidget {
  final Station station;
  final ScanResult? initialScanResult;

  const SubmitPriceScreen({
    super.key,
    required this.station,
    this.initialScanResult,
  });

  @override
  State<SubmitPriceScreen> createState() => _SubmitPriceScreenState();
}

class _SubmitPriceScreenState extends State<SubmitPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<FuelType, TextEditingController> _controllers = {
    for (final type in FuelType.values) type: TextEditingController(),
  };
  bool _isSubmitting = false;
  ImageMetadata? _scanMetadata;
  bool _scanParsedPrices = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialScanResult != null) {
      // Apply scan result after the first frame so the form is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleScanResult(widget.initialScanResult!, autoSubmit: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleScanResult(ScanResult result, {bool autoSubmit = false}) {
    if (result.prices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotRecognizePrices)),
      );
      return;
    }

    final hasCorePrice =
        result.prices.containsKey(FuelType.diesel) ||
        result.prices.containsKey(FuelType.petrol95);
    setState(() {
      _scanMetadata = result.imageMetadata;
      _scanParsedPrices = hasCorePrice;
    });

    int filled = 0;
    for (final entry in result.prices.entries) {
      _controllers[entry.key]?.text = entry.value.toStringAsFixed(2);
      filled++;
    }

    final suffix = switch (result.cropMethod) {
      CropMethod.autoCrop => ' (auto-detected)',
      CropMethod.manualCrop => ' (manual selection)',
      CropMethod.none => '',
    };

    final metadataNote = _hasValidPhotoMetadata
        ? ' (photo location verified)'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.l10n.filledPricesFromScan(filled)}$suffix$metadataNote',
        ),
      ),
    );

    // Auto-submit when coming from the capture flow (user already confirmed
    // prices on the scan screen) or when photo has valid location metadata.
    if (autoSubmit || _hasValidPhotoMetadata) {
      _submit(autoSubmit: true);
    }
  }

  bool get _hasValidPhotoMetadata {
    if (!_scanParsedPrices) return false;
    final meta = _scanMetadata;
    if (meta == null) return false;
    return meta.isValidForStation(
      widget.station.latitude,
      widget.station.longitude,
      maxMeters: AppConstants.maxReportDistanceMeters,
    );
  }

  Map<FuelType, double> _filledPrices() {
    final prices = <FuelType, double>{};
    for (final type in FuelType.values) {
      final text = _controllers[type]!.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) prices[type] = value;
      }
    }
    return prices;
  }

  Future<void> _submit({bool autoSubmit = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final isAdmin = context.read<UserProvider>().isAdmin;

    if (isAdmin) {
      debugPrint('[SubmitPrice] Location check bypassed — admin user');
    } else if (_hasValidPhotoMetadata) {
      debugPrint(
        '[SubmitPrice] Location check bypassed — photo metadata valid',
      );
    } else {
      final locationProvider = context.read<LocationProvider>();
      if (!locationProvider.hasLocation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.locationUnavailable)),
        );
        return;
      }
      final pos = locationProvider.position!;
      final distance = DistanceService.distanceInMeters(
        pos.latitude,
        pos.longitude,
        widget.station.latitude,
        widget.station.longitude,
      );
      if (distance > AppConstants.maxReportDistanceMeters) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.mustBeNearStation(
                AppConstants.maxReportDistanceMeters.round(),
                distance.round(),
              ),
            ),
          ),
        );
        return;
      }
    }

    final prices = _filledPrices();
    if (prices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterAtLeastOnePrice)),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();

    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.needAccountToReport)));
      final result = await Navigator.pushNamed(context, AppRoutes.auth);
      if (result != true || !mounted) return;
    }

    final userId = context.read<UserProvider>().user.id;
    final priceProvider = context.read<PriceProvider>();

    final skipped = <FuelType>[];
    final toSubmit = <FuelType, double>{};
    Duration maxRemaining = Duration.zero;

    for (final entry in prices.entries) {
      final remaining = await priceProvider.getCooldownRemaining(
        userId: userId,
        stationId: widget.station.id,
        fuelType: entry.key,
      );
      if (remaining != null) {
        skipped.add(entry.key);
        if (remaining > maxRemaining) maxRemaining = remaining;
      } else {
        toSubmit[entry.key] = entry.value;
      }
    }

    if (toSubmit.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.allOnCooldown)));
      return;
    }

    // Skip confirmation dialog when auto-submitting from a verified photo scan
    // — the user already confirmed the prices on the scan confirmation screen.
    if (!autoSubmit) {
      final skipConfirm = await CooldownPrefsService.shouldSkipConfirmation();
      if (!skipConfirm) {
        if (!mounted) return;
        final confirmed = await _showConfirmationDialog(toSubmit.keys.toList());
        if (confirmed != true) return;
      }
    }

    setState(() => _isSubmitting = true);

    int successCount = 0;
    String? lastError;

    for (final entry in toSubmit.entries) {
      final success = await priceProvider.submitReport(
        stationId: widget.station.id,
        fuelType: entry.key,
        price: entry.value,
        userId: userId,
      );
      if (success) {
        successCount++;
      } else {
        lastError = priceProvider.error;
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (successCount > 0) {
      final userProvider = context.read<UserProvider>();
      final stationProvider = context.read<StationProvider>();
      await userProvider.refreshProfile();
      stationProvider.refreshStations();
    }

    if (!mounted) return;

    final parts = <String>[];
    if (successCount > 0) {
      parts.add('$successCount price${successCount > 1 ? 's' : ''} reported');
    }
    if (skipped.isNotEmpty) {
      parts.add(
        '${skipped.map((t) => t.localizedName(context)).join(", ")} skipped (cooldown)',
      );
    }
    if (lastError != null) {
      parts.add('Some submissions failed');
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(parts.join('. '))));

    if (successCount > 0) {
      Navigator.pop(context);
    }
  }

  Future<bool?> _showConfirmationDialog(List<FuelType> fuelTypes) {
    bool doNotShowAgain = false;
    final typeNames = fuelTypes.map((t) => t.localizedName(context)).join(', ');

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.confirmPriceSubmission),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.confirmSubmissionBody(typeNames)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: doNotShowAgain,
                        onChanged: (value) {
                          setDialogState(() => doNotShowAgain = value ?? false);
                        },
                      ),
                      Flexible(child: Text(context.l10n.doNotShowAgain)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    if (doNotShowAgain) {
                      await CooldownPrefsService.setSkipConfirmation(true);
                    }
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: Text(context.l10n.submit),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressLine = [
      widget.station.address,
      widget.station.city,
    ].where((s) => s.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.l10n.reportPrice,
          style: AppTextStyles.title(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  BrandLogo(brand: widget.station.brand, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.station.name,
                          style: AppTextStyles.bodyMedium(context),
                        ),
                        if (addressLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(addressLine, style: AppTextStyles.meta(context)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.enterPricesInstruction,
              style: AppTextStyles.bodyMedium(context),
            ),
            const SizedBox(height: 12),
            ScanPriceButton(onScanned: _handleScanResult),
            const SizedBox(height: 12),
            for (final type in FuelType.values) ...[
              PriceInputField(controller: _controllers[type]!, fuelType: type),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            _GradientSubmitButton(
              isSubmitting: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientSubmitButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _GradientSubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  State<_GradientSubmitButton> createState() => _GradientSubmitButtonState();
}

class _GradientSubmitButtonState extends State<_GradientSubmitButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.isSubmitting
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isSubmitting
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF00d1ff), const Color(0xFF0091b3)]
                  : [const Color(0xFF0056b3), const Color(0xFF003f87)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF00d1ff) : const Color(0xFF0056b3))
                        .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppColors.darkBackground : Colors.white,
                    ),
                  )
                : Text(
                    context.l10n.submitReport,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
