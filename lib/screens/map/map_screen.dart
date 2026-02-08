import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import 'widgets/brand_filter_bar.dart';
import 'widgets/fuel_filter_bar.dart';

import 'widgets/station_bottom_sheet.dart';
import 'widgets/station_marker.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = context.read<StationProvider>();
      if (stationProvider.stations.isEmpty) {
        stationProvider.loadStations();
      }
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

    // Auto-center on user location once available
    if (locationProvider.hasLocation && !_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pos = locationProvider.position!;
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      });
    }

    final filtered = stationProvider.filteredStations;

    return Scaffold(
      body: Stack(
        children: [
          // Map
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
              // User location marker
              if (locationProvider.hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        locationProvider.position!.latitude,
                        locationProvider.position!.longitude,
                      ),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              // Station markers (filtered by brand)
              MarkerLayer(
                markers: filtered.map((station) {
                  final price = stationProvider.getPriceForStation(station.id);
                  return Marker(
                    point: LatLng(station.latitude, station.longitude),
                    width: 80,
                    height: 55,
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
              ),
            ],
          ),
          // Fuel filter bar at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: const FuelFilterBar(),
          ),
          // Brand filter button — top right, below fuel filter bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            right: 16,
            child: const BrandFilterButton(),
          ),
          // Locate button — floats above the bottom sheet
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
                child: FloatingActionButton.small(
                  heroTag: 'locateMe',
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location),
                ),
              );
            },
          ),
          // Bottom sheet
          Positioned.fill(
            child: StationBottomSheet(sheetController: _sheetController),
          ),
        ],
      ),
    );
  }
}
