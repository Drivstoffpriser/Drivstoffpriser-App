import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/fuel_type.dart';
import '../../models/station.dart';
import '../../providers/price_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
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

    final price = double.parse(_priceController.text);
    final userId = context.read<UserProvider>().user.id;
    final priceProvider = context.read<PriceProvider>();

    final success = await priceProvider.submitReport(
      stationId: widget.station.id,
      fuelType: _selectedFuelType,
      price: price,
      userId: userId,
    );

    if (success && mounted) {
      context.read<UserProvider>().incrementReportCount();
      // Reload station prices
      await context.read<StationProvider>().loadStations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price reported successfully!')),
        );
        Navigator.pop(context);
      }
    }
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
                    CircleAvatar(
                      child: Text(widget.station.brand.substring(0, 1)),
                    ),
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
