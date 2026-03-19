import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
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

  const SubmitPriceScreen({super.key, required this.station});

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
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleScanResult(ScanResult result) {
    if (result.prices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not recognize any fuel prices')),
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
          'Filled $filled price${filled > 1 ? 's' : ''} from scan$suffix$metadataNote',
        ),
      ),
    );
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasValidPhotoMetadata) {
      debugPrint(
        '[SubmitPrice] Location check bypassed — photo metadata valid',
      );
    } else {
      final locationProvider = context.read<LocationProvider>();
      if (!locationProvider.hasLocation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location unavailable. Enable location services or scan a photo taken at the station today.',
            ),
          ),
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
              'You must be within ${AppConstants.maxReportDistanceMeters.round()}m of the station. '
              'You are ${DistanceService.formatDistance(distance)} away. '
              'Tip: Scan a photo taken at the station today to submit remotely.',
            ),
          ),
        );
        return;
      }
    }

    final prices = _filledPrices();
    if (prices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one fuel price.')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();

    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need an account to report prices.')),
      );
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
      final minutesLeft = maxRemaining.inMinutes + 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All selected fuel types are on cooldown: '
            '${skipped.map((t) => t.displayName).join(", ")}. '
            'Please wait $minutesLeft minute${minutesLeft != 1 ? 's' : ''} before submitting again.',
          ),
        ),
      );
      return;
    }

    final skipConfirm = await CooldownPrefsService.shouldSkipConfirmation();
    if (!skipConfirm) {
      if (!mounted) return;
      final confirmed = await _showConfirmationDialog(toSubmit.keys.toList());
      if (confirmed != true) return;
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
      await context.read<UserProvider>().incrementReportCount();
      context.read<StationProvider>().refreshFromFirestore();
    }

    if (!mounted) return;

    final parts = <String>[];
    if (successCount > 0) {
      parts.add('$successCount price${successCount > 1 ? 's' : ''} reported');
    }
    if (skipped.isNotEmpty) {
      parts.add(
        '${skipped.map((t) => t.displayName).join(", ")} skipped (cooldown)',
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
    final typeNames = fuelTypes.map((t) => t.displayName).join(', ');

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Price Submission'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submitting prices for: $typeNames.\n\n'
                    'After submitting, you will not be able to update '
                    'these fuel types at this station for 1 hour.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: doNotShowAgain,
                        onChanged: (value) {
                          setDialogState(() => doNotShowAgain = value ?? false);
                        },
                      ),
                      const Flexible(child: Text('Do not show this again')),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (doNotShowAgain) {
                      await CooldownPrefsService.setSkipConfirmation(true);
                    }
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Submit'),
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
        title: Text('Report Price', style: AppTextStyles.title(context)),
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
                borderRadius: BorderRadius.circular(12),
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
              'Enter prices (fill in any you know)',
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
            _PressableButton(
              onPressed: _isSubmitting ? () {} : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Report',
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _PressableButton({required this.onPressed, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: widget.child,
        ),
      ),
    );
  }
}
