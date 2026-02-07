import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/fuel_type.dart';
import '../../models/station.dart';
import '../../providers/location_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/cooldown_prefs_service.dart';
import '../../services/distance_service.dart';
import '../../widgets/brand_logo.dart';
import 'widgets/price_input_field.dart';

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

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Collect fuel types that have a price entered.
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

    // Proximity check
    final locationProvider = context.read<LocationProvider>();
    if (!locationProvider.hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location unavailable. Enable location services to report prices.'),
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
          ),
        ),
      );
      return;
    }

    final prices = _filledPrices();
    if (prices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one fuel price.')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();

    // Auth gate
    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need an account to report prices.')),
      );
      final result = await Navigator.pushNamed(context, AppRoutes.auth);
      if (result != true || !mounted) return;
    }

    final userId = context.read<UserProvider>().user.id;
    final priceProvider = context.read<PriceProvider>();

    // Check cooldowns for each fuel type
    final skipped = <FuelType>[];
    final toSubmit = <FuelType, double>{};

    for (final entry in prices.entries) {
      final remaining = await priceProvider.getCooldownRemaining(
        userId: userId,
        stationId: widget.station.id,
        fuelType: entry.key,
      );
      if (remaining != null) {
        skipped.add(entry.key);
      } else {
        toSubmit[entry.key] = entry.value;
      }
    }

    if (toSubmit.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All selected fuel types are on cooldown: '
            '${skipped.map((t) => t.displayName).join(", ")}. '
            'Please wait before submitting again.',
          ),
        ),
      );
      return;
    }

    // Confirmation dialog (unless user opted out)
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
      appBar: AppBar(title: const Text('Report Price')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Station info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    BrandLogo(brand: widget.station.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.station.name,
                              style: Theme.of(context).textTheme.titleSmall),
                          if (addressLine.isNotEmpty)
                            Text(addressLine,
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Price inputs — one per fuel type
            Text('Enter prices (fill in any you know)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final type in FuelType.values) ...[
              PriceInputField(
                controller: _controllers[type]!,
                fuelType: type,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 20),

            // Submit button
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
