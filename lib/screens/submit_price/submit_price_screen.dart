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

    // Store photo metadata for location bypass — require at least diesel or 95
    final hasCorePrice = result.prices.containsKey(FuelType.diesel) ||
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
      SnackBar(content: Text('Filled $filled price${filled > 1 ? 's' : ''} from scan$suffix$metadataNote')),
    );
  }

  /// Whether the scanned photo qualifies for remote submission:
  /// EXIF GPS within 1km of station + taken in last 24h + OCR parsed at least
  /// one core price (diesel or petrol 95).
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

  /// Collect fuel types that have a price entered.
  Map<FuelType, double> _filledPrices() {
    final prices = <FuelType, double>{};
    for (final type in FuelType.values) {
      final text = _controllers[type]!.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text.replaceAll(',', '.'));
        if (value != null) prices[type] = value;
      }
    }
    return prices;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Proximity check — bypassed when photo EXIF metadata proves the user
    // was at the station today (GPS within 1km + photo taken same day).
    if (_hasValidPhotoMetadata) {
      debugPrint('[SubmitPrice] Location check bypassed — photo metadata valid '
          '(lat=${_scanMetadata!.latitude}, lng=${_scanMetadata!.longitude}, '
          'date=${_scanMetadata!.dateTime})');
    } else {
      final locationProvider = context.read<LocationProvider>();
      if (!locationProvider.hasLocation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location unavailable. Enable location services or scan a photo taken at the station today.'),
          ),
        );
        return;
      }
      final pos = locationProvider.position!;
      final distance = DistanceService.distanceInMeters(
        pos.latitude, pos.longitude,
        widget.station.latitude, widget.station.longitude,
    final isDark = context.read<UserProvider>().isDarkMode;
    final locationProvider = context.read<LocationProvider>();
    if (!locationProvider.hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location unavailable. Enable location services to report prices.', style: AppTextStyles.label(isDark).copyWith(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final pos = locationProvider.position!;
    final distance = DistanceService.distanceInMeters(
      pos.latitude, pos.longitude,
      widget.station.latitude, widget.station.longitude,
    );
    if (distance > AppConstants.maxReportDistanceMeters) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be within ${AppConstants.maxReportDistanceMeters.round()}m of the station. '
            'You are ${DistanceService.formatDistance(distance)} away.',
            style: AppTextStyles.label(isDark).copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text('Enter at least one fuel price.', style: AppTextStyles.label(isDark).copyWith(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();

    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need an account to report prices.', style: AppTextStyles.label(isDark).copyWith(color: Colors.white)),
          backgroundColor: AppColors.accent,
        ),
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
      final minutesLeft = maxRemaining.inMinutes + 1; // round up
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All selected fuel types are on cooldown: '
            '${skipped.map((t) => t.displayName).join(", ")}. '
            'Please wait $minutesLeft minute${minutesLeft != 1 ? 's' : ''} before submitting again.',
            'Please wait.',
            style: AppTextStyles.label(isDark).copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
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
    for (final entry in toSubmit.entries) {
      final success = await priceProvider.submitReport(
        stationId: widget.station.id,
        fuelType: entry.key,
        price: entry.value,
        userId: userId,
      );
      if (success) successCount++;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (successCount > 0) {
      await context.read<UserProvider>().incrementReportCount();
      // Refresh cached prices so the list/map reflect the new submission
      context.read<StationProvider>().refreshFromFirestore();
    }

    if (!mounted) return;

    // Build result message
    final parts = <String>[];
    if (successCount > 0) {
      parts.add('$successCount price${successCount > 1 ? 's' : ''} reported');
    }
    if (skipped.isNotEmpty) {
      parts.add('${skipped.map((t) => t.displayName).join(", ")} skipped (cooldown)');
    }
    if (lastError != null) {
      parts.add('Some submissions failed');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(parts.join('. '))),
    );

    if (successCount > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully reported $successCount price${successCount > 1 ? 's' : ''}', style: AppTextStyles.label(isDark).copyWith(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<bool?> _showConfirmationDialog(List<FuelType> fuelTypes) {
    bool doNotShowAgain = false;
    final isDark = context.read<UserProvider>().isDarkMode;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceElevated(isDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Confirm Submission', style: AppTextStyles.heading(isDark)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'You are submitting prices for ${fuelTypes.length} fuel types. You cannot update these again for 1 hour.',
                    style: AppTextStyles.body(isDark),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: doNotShowAgain,
                          activeColor: AppColors.accent,
                          onChanged: (value) {
                            setDialogState(() => doNotShowAgain = value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Don\'t show again', style: AppTextStyles.label(isDark)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(isDark))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (doNotShowAgain) {
                      await CooldownPrefsService.setSkipConfirmation(true);
                    }
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirm'),
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
    final isDark = context.watch<UserProvider>().isDarkMode;
    final addressLine = [
      widget.station.address,
      widget.station.city,
    ].where((s) => s.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text('Report Price', style: AppTextStyles.heading(isDark)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(isDark)),
              ),
              child: Row(
                children: [
                  BrandLogo(brand: widget.station.brand, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.station.name, style: AppTextStyles.heading(isDark).copyWith(fontSize: 16)),
                        if (addressLine.isNotEmpty)
                          Text(addressLine, style: AppTextStyles.label(isDark).copyWith(color: AppColors.textMuted(isDark))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Enter Current Prices',
              style: AppTextStyles.heading(isDark).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the prices as they appear on the station totem.',
              style: AppTextStyles.label(isDark).copyWith(color: AppColors.textMuted(isDark)),
            ),
            const SizedBox(height: 24),

            // Price inputs — one per fuel type
            Text('Enter prices (fill in any you know)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            ScanPriceButton(onScanned: _handleScanResult),
            const SizedBox(height: 12),
            for (final type in FuelType.values) ...[
              PriceInputField(
            ...FuelType.values.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PriceInputField(
                controller: _controllers[type]!,
                fuelType: type,
              ),
            )),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Submit Report',
                        style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
