import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../models/fuel_type.dart';
import '../../models/station.dart';
import '../../providers/price_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/cooldown_prefs_service.dart';
import '../../widgets/brand_logo.dart';
import 'widgets/fuel_type_selector.dart';
import 'widgets/price_input_field.dart';

class SubmitPriceScreen extends StatefulWidget {
  final Station station;

  const SubmitPriceScreen({super.key, required this.station});

  @override
  State<SubmitPriceScreen> createState() => _SubmitPriceScreenState();
}

class _SubmitPriceScreenState extends State<SubmitPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  late FuelType _selectedFuelType;

  @override
  void initState() {
    super.initState();
    _selectedFuelType = context.read<StationProvider>().selectedFuelType;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();

    // Auth gate: require email account to submit prices
    if (!userProvider.isAuthenticated) {
      final result = await Navigator.pushNamed(context, AppRoutes.auth);
      if (result != true || !mounted) return;
    }

    final price = double.parse(_priceController.text);
    final userId = context.read<UserProvider>().user.id;
    final priceProvider = context.read<PriceProvider>();

    // Cooldown check
    final remaining = await priceProvider.getCooldownRemaining(
      userId: userId,
      stationId: widget.station.id,
      fuelType: _selectedFuelType,
    );

    if (remaining != null) {
      if (!mounted) return;
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You already reported ${_selectedFuelType.displayName} at this station. '
            'Please wait ${minutes}m ${seconds}s before submitting again.',
          ),
        ),
      );
      return;
    }

    // Confirmation dialog (unless user opted out)
    final skipConfirm = await CooldownPrefsService.shouldSkipConfirmation();
    if (!skipConfirm) {
      if (!mounted) return;
      final confirmed = await _showConfirmationDialog();
      if (confirmed != true) return;
    }

    final success = await priceProvider.submitReport(
      stationId: widget.station.id,
      fuelType: _selectedFuelType,
      price: price,
      userId: userId,
    );

    if (success && mounted) {
      await context.read<UserProvider>().incrementReportCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price reported successfully!')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<bool?> _showConfirmationDialog() {
    bool doNotShowAgain = false;

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
                  const Text(
                    'Please double-check your price. After submitting, '
                    'you will not be able to update this fuel type at this '
                    'station for 1 hour.',
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
    final priceProvider = context.watch<PriceProvider>();

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
                          Text('${widget.station.address}, ${widget.station.city}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fuel type selector
            Text('Fuel Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FuelTypeSelector(
              selected: _selectedFuelType,
              onChanged: (type) => setState(() => _selectedFuelType = type),
            ),
            const SizedBox(height: 24),

            // Price input
            PriceInputField(
              controller: _priceController,
              fuelType: _selectedFuelType,
            ),
            const SizedBox(height: 32),

            // Submit button
            FilledButton(
              onPressed: priceProvider.isSubmitting ? null : _submit,
              child: priceProvider.isSubmitting
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
