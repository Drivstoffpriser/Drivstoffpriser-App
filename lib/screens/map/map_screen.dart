import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
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
    final isDark = context.watch<UserProvider>().isDarkMode;
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    if (locationProvider.hasLocation && !_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pos = locationProvider.position!;
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      });
    }

    // Once we know the user's position (or location failed), set the
    // user location on StationProvider so filteredStations can work.
    // Station loading + Overpass fetch already started in main().
    if (!_hasSetUserLocation) {
    if (!_hasTriggeredStationFetch) {
      if (locationProvider.hasLocation) {
        _hasSetUserLocation = true;
        final pos = locationProvider.position!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<StationProvider>().setUserLocation(
                pos.latitude, pos.longitude);
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
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  if (locationProvider.hasLocation)
                    Marker(
                      point: LatLng(
                        locationProvider.position!.latitude,
                        locationProvider.position!.longitude,
                      ),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
<<<<<<< HEAD
              // Station markers (filtered by brand and clustered)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 110, // Grouping stations on zoom out
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
                      width: 80,
                      height: 70,
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
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
=======
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: MarkerClusterLayerWidget(
                  key: ValueKey(stationProvider.selectedFuelType),
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
                          color: AppColors.accent,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
>>>>>>> 2bd3d39 (ui overhaul)
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
<<<<<<< HEAD
          // Fuel filter bar + brand filter at top
=======
>>>>>>> 2bd3d39 (ui overhaul)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
<<<<<<< HEAD
            child: const FuelFilterBar(
              trailing: BrandFilterButton(),
            ),
=======
            child: const FuelFilterBar(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: const BrandFilterButton(),
>>>>>>> 2bd3d39 (ui overhaul)
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
              final bottomOffset = sheetPixels + 12 + 100;

              return Positioned(
                right: 16,
                bottom: bottomOffset,
                child: GestureDetector(
                  onTap: locationProvider.isLoading
                      ? null
                      : locationProvider.hasLocation
                      ? _centerOnUser
                      : () => context.read<LocationProvider>().fetchLocation(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated(isDark),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(isDark)),
                    ),
                    child: locationProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            color: AppColors.textPrimary(isDark),
                            size: 20,
                          ),
                  ),
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
