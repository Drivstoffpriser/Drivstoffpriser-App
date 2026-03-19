import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import 'widgets/brand_filter_bar.dart';
import 'widgets/fuel_filter_bar.dart';

import 'widgets/station_bottom_sheet.dart';
import 'widgets/station_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _hasCenteredOnUser = false;
  bool _hasSetUserLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchLocation();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _centerOnUser() {
    final pos = context.read<LocationProvider>().position;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    if (locationProvider.hasLocation && !_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pos = locationProvider.position!;
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      });
    }

    if (!_hasSetUserLocation) {
      if (locationProvider.hasLocation) {
        _hasSetUserLocation = true;
        final pos = locationProvider.position!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<StationProvider>().setUserLocation(
            pos.latitude,
            pos.longitude,
          );
        });
      } else if (locationProvider.error != null) {
        _hasSetUserLocation = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<StationProvider>().setUserLocation(
            AppConstants.defaultMapCenter.latitude,
            AppConstants.defaultMapCenter.longitude,
          );
        });
      }
    }

    final filtered = stationProvider.filteredStations;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: AppConstants.defaultMapCenter,
              initialZoom: AppConstants.defaultMapZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fuel_price_tracker',
              ),
              MarkerLayer(
                markers: [
                  if (locationProvider.hasLocation)
                    Marker(
                      point: LatLng(
                        locationProvider.position!.latitude,
                        locationProvider.position!.longitude,
                      ),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 110,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: filtered.map((station) {
                    final price = stationProvider.getPriceForStation(
                      station.id,
                    );
                    return Marker(
                      point: LatLng(station.latitude, station.longitude),
                      width: 48,
                      height: 48,
                      child: StationMarker(
                        station: station,
                        price: price,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.stationDetail,
                            arguments: station,
                          );
                        },
                      ),
                    );
                  }).toList(),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF2563EB),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: FuelFilterBar(trailing: const BrandFilterButton()),
          ),
          ListenableBuilder(
            listenable: _sheetController,
            builder: (context, _) {
              final screenHeight = MediaQuery.of(context).size.height;
              double sheetPixels;
              try {
                sheetPixels = _sheetController.pixels;
              } catch (_) {
                sheetPixels = screenHeight * 0.25;
              }
              final bottomOffset = sheetPixels + 8;

              return Positioned(
                right: 16,
                bottom: bottomOffset,
                child: _LocateButton(
                  isLoading: locationProvider.isLoading,
                  hasLocation: locationProvider.hasLocation,
                  onPressed: locationProvider.isLoading
                      ? null
                      : locationProvider.hasLocation
                      ? _centerOnUser
                      : () => context.read<LocationProvider>().fetchLocation(),
                ),
              );
            },
          ),
          Positioned.fill(
            child: StationBottomSheet(sheetController: _sheetController),
          ),
        ],
      ),
    );
  }
}

class _LocateButton extends StatefulWidget {
  final bool isLoading;
  final bool hasLocation;
  final VoidCallback? onPressed;

  const _LocateButton({
    required this.isLoading,
    required this.hasLocation,
    this.onPressed,
  });

  @override
  State<_LocateButton> createState() => _LocateButtonState();
}

class _LocateButtonState extends State<_LocateButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border(context), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.my_location_outlined,
                    size: 20,
                    color: AppColors.textPrimary(context),
                  ),
          ),
        ),
      ),
    );
  }
}
