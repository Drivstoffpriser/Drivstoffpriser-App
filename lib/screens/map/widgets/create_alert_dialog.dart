import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../models/fuel_type.dart';
import '../../../models/station.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/station_provider.dart';
import '../../../providers/user_provider.dart';

class CreateAlertDialog extends StatefulWidget {
  const CreateAlertDialog({super.key});

  @override
  State<CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<CreateAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  FuelType _fuelType = FuelType.petrol95;
  String? _stationId; // null = "Any station"
  double _maxDistanceKm = 5;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stations = context.read<StationProvider>().stations;

    return AlertDialog(
      title: const Text('Create Price Alert'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Target price
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target price (${AppConstants.currencySymbol})',
                  hintText: 'e.g. 20.50',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a target price';
                  }
                  final price = double.tryParse(value);
                  if (price == null) return 'Invalid number';
                  if (price < AppConstants.minFuelPrice ||
                      price > AppConstants.maxFuelPrice) {
                    return 'Price must be between '
                        '${AppConstants.minFuelPrice} and '
                        '${AppConstants.maxFuelPrice} '
                        '${AppConstants.currencySymbol}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fuel type
              DropdownButtonFormField<FuelType>(
                initialValue: _fuelType,
                decoration: const InputDecoration(labelText: 'Fuel type'),
                items: FuelType.values.map((ft) {
                  return DropdownMenuItem(
                    value: ft,
                    child: Text(ft.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _fuelType = value);
                },
              ),
              const SizedBox(height: 16),

              // Station
              DropdownButtonFormField<String?>(
                initialValue: _stationId,
                decoration: const InputDecoration(labelText: 'Station'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Any station'),
                  ),
                  ...stations.map((s) {
                    return DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (value) => setState(() => _stationId = value),
              ),
              const SizedBox(height: 16),

              // Max distance slider (only when "any station")
              if (_stationId == null) ...[
                Row(
                  children: [
                    const Text('Max distance'),
                    const Spacer(),
                    Text('${_maxDistanceKm.round()} km',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _maxDistanceKm,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '${_maxDistanceKm.round()} km',
                  onChanged: (v) => setState(() => _maxDistanceKm = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _showMyAlerts(context),
          child: const Text('My Alerts'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<UserProvider>().user.id;
    final locationProvider = context.read<LocationProvider>();
    final alertProvider = context.read<AlertProvider>();

    final lat = locationProvider.position?.latitude ??
        AppConstants.defaultMapCenter.latitude;
    final lng = locationProvider.position?.longitude ??
        AppConstants.defaultMapCenter.longitude;

    alertProvider.createAlert(
      userId: userId,
      fuelType: _fuelType,
      targetPrice: double.parse(_priceController.text),
      stationId: _stationId,
      maxDistanceKm: _maxDistanceKm,
      userLat: lat,
      userLng: lng,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Price alert created')),
    );
  }

  void _showMyAlerts(BuildContext dialogContext) {
    showModalBottomSheet(
      context: dialogContext,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) =>
            _MyAlertsSheet(scrollController: scrollController),
      ),
    );
  }
}

class _MyAlertsSheet extends StatelessWidget {
  final ScrollController scrollController;

  const _MyAlertsSheet({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final alerts = alertProvider.alerts;
    final stations = context.read<StationProvider>().stations;
    final stationMap = {for (final s in stations) s.id: s};

    if (alerts.isEmpty) {
      return const Center(child: Text('No alerts yet'));
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final Station? station =
            alert.stationId != null ? stationMap[alert.stationId] : null;
        final stationLabel = station?.name ?? 'Any station';

        return ListTile(
          title: Text(
            '${alert.fuelType.displayName} ≤ '
            '${alert.targetPrice.toStringAsFixed(2)} '
            '${AppConstants.currencySymbol}',
          ),
          subtitle: Text(
            alert.stationId != null
                ? stationLabel
                : '$stationLabel (within ${alert.maxDistanceKm.round()} km)',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: alert.isActive,
                onChanged: (_) => alertProvider.toggleAlert(alert),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => alertProvider.deleteAlert(alert.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
