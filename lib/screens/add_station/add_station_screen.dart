import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/station_submission.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class AddStationScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final StationSubmission? editSubmission;

  const AddStationScreen({
    super.key,
    this.initialLocation,
    this.editSubmission,
  });

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
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

  bool get _isEditing => widget.editSubmission != null;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final edit = widget.editSubmission;
    if (edit != null) {
      // Pre-fill from existing submission
      _selectedLocation = LatLng(edit.latitude, edit.longitude);
      _nameController.text = edit.name;
      _addressController.text = edit.address;
      _cityController.text = edit.city;
      if (_knownBrands.contains(edit.brand)) {
        _selectedBrand = edit.brand;
      } else {
        _isCustomBrand = true;
        _customBrandController.text = edit.brand;
      }
    } else {
      final loc = widget.initialLocation;
      if (loc != null) {
        _selectedLocation = loc;
      } else {
        final pos = context.read<LocationProvider>().position;
        _selectedLocation = pos != null
            ? LatLng(pos.latitude, pos.longitude)
            : AppConstants.defaultMapCenter;
      }
      // Auto-fill address for the initial location (not when editing)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reverseGeocode(_selectedLocation);
      });
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
        headers: {'User-Agent': 'TankVenn/1.0'},
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
      // Silently fail — user can still type manually
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

    setState(() => _isSubmitting = true);

    try {
      if (_isEditing) {
        await FirestoreService.updateStationSubmission(
          docId: widget.editSubmission!.id,
          name: _nameController.text.trim(),
          brand: brand,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          submittedBy: userProvider.user.id,
        );
      } else {
        await FirestoreService.submitNewStation(
          name: _nameController.text.trim(),
          brand: brand,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          submittedBy: userProvider.user.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? context.l10n.addStationUpdated
                : context.l10n.addStationSubmitted,
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.addStationFailed)));
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
          _isEditing ? context.l10n.editStation : context.l10n.addStation,
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
            // Map pin picker
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

            // Station name
            TextFormField(
              controller: _nameController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.addStationName,
                hintText: context.l10n.addStationNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.addStationNameRequired
                  : null,
            ),
            const SizedBox(height: 16),

            // Brand selector
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
                  hintText: context.l10n.addStationCustomBrandHint,
                ),
                validator: (v) =>
                    _isCustomBrand && (v == null || v.trim().isEmpty)
                    ? context.l10n.addStationBrandRequired
                    : null,
              ),
            ],
            const SizedBox(height: 16),

            // Address (auto-filled, still editable)
            TextFormField(
              controller: _addressController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.addStationAddress,
                hintText: context.l10n.addStationAddressHint,
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

            // City (auto-filled, still editable)
            TextFormField(
              controller: _cityController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.addStationCity,
                hintText: context.l10n.addStationCityHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.addStationCityRequired
                  : null,
            ),
            const SizedBox(height: 24),

            // Submit / Sign in button
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
                      : Text(
                          _isEditing
                              ? context.l10n.addStationUpdateButton
                              : context.l10n.addStationSubmitButton,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
