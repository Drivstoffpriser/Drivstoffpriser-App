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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/station.dart';
import '../../models/station_modify_request.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class EditStationScreen extends StatefulWidget {
  final Station station;

  const EditStationScreen({super.key, required this.station});

  @override
  State<EditStationScreen> createState() => _EditStationScreenState();
}

class _EditStationScreenState extends State<EditStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _customBrandController = TextEditingController();

  late LatLng _selectedLocation;
  late final MapController _mapController;
  String? _selectedBrand;
  bool _isCustomBrand = false;
  bool _isSubmitting = false;
  bool _isGeocodingLoading = false;

  static const _knownBrands = [
    'Circle K',
    'Esso',
    'Shell',
    'YX',
    'Uno-X',
    'St1',
    'YX Truck',
    'Tanken',
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final s = widget.station;
    _selectedLocation = LatLng(s.latitude, s.longitude);
    _nameController.text = s.name;
    _addressController.text = s.address;
    _cityController.text = s.city;
    if (_knownBrands.contains(s.brand)) {
      _selectedBrand = s.brand;
    } else {
      _isCustomBrand = true;
      _customBrandController.text = s.brand;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _customBrandController.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isGeocodingLoading = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Drivstoffpriser/1.0'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] as String? ?? '';
          final houseNumber = address['house_number'] as String? ?? '';
          final street = [
            road,
            houseNumber,
          ].where((s) => s.isNotEmpty).join(' ');
          final city =
              address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['municipality'] as String? ??
              '';
          _addressController.text = street;
          _cityController.text = city;
        }
      }
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _isGeocodingLoading = false);
    }
  }

  void _onMapTap(LatLng point) {
    setState(() => _selectedLocation = point);
    _reverseGeocode(point);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final brand = _isCustomBrand
        ? _customBrandController.text.trim()
        : _selectedBrand;
    if (brand == null || brand.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addStationSelectBrand)),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final s = widget.station;

    final request = StationModifyRequest(
      id: '',
      stationId: s.id,
      originalName: s.name,
      originalBrand: s.brand,
      originalAddress: s.address,
      originalCity: s.city,
      originalLatitude: s.latitude,
      originalLongitude: s.longitude,
      proposedName: _nameController.text.trim(),
      proposedBrand: brand,
      proposedAddress: _addressController.text.trim(),
      proposedCity: _cityController.text.trim(),
      proposedLatitude: _selectedLocation.latitude,
      proposedLongitude: _selectedLocation.longitude,
      submittedBy: userProvider.user.id,
    );

    if (!request.hasChanges) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noChangesToSubmit)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirestoreService.submitModifyRequest(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.modifyRequestSubmitted)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.modifyRequestFailed)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.editStationInfo,
          style: AppTextStyles.title(context),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          children: [
            Text(
              context.l10n.addStationTapMap,
              style: AppTextStyles.label(context),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 17,
                    onTap: (_, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tileUrl,
                      userAgentPackageName: 'com.example.fuel_price_tracker',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            color: AppColors.primaryContainer(context),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.addStationName,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.addStationNameRequired
                  : null,
            ),
            const SizedBox(height: 16),

            Text(
              context.l10n.addStationBrand,
              style: AppTextStyles.labelBold(context),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._knownBrands.map(
                  (brand) => ChoiceChip(
                    label: Text(brand),
                    selected: !_isCustomBrand && _selectedBrand == brand,
                    onSelected: (selected) {
                      setState(() {
                        _isCustomBrand = false;
                        _selectedBrand = selected ? brand : null;
                      });
                    },
                  ),
                ),
                ChoiceChip(
                  label: Text(context.l10n.addStationNoChain),
                  selected: _isCustomBrand,
                  onSelected: (selected) {
                    setState(() {
                      _isCustomBrand = selected;
                      if (selected) _selectedBrand = null;
                    });
                  },
                ),
              ],
            ),
            if (_isCustomBrand) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customBrandController,
                style: AppTextStyles.body(context),
                decoration: InputDecoration(
                  labelText: context.l10n.addStationCustomBrand,
                ),
                validator: (v) =>
                    _isCustomBrand && (v == null || v.trim().isEmpty)
                    ? context.l10n.addStationBrandRequired
                    : null,
              ),
            ],
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.addStationAddress,
                suffixIcon: _isGeocodingLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.addStationAddressRequired
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cityController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.addStationCity,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.addStationCityRequired
                  : null,
            ),
            const SizedBox(height: 24),

            if (!context.watch<UserProvider>().isAuthenticated) ...[
              Text(
                context.l10n.needAccountToReport,
                style: AppTextStyles.label(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.auth),
                  child: Text(context.l10n.createAccount),
                ),
              ),
            ] else
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.submitChanges),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
