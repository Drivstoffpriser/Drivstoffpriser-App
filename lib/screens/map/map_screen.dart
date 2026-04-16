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

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/station.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/web_constrained.dart';
import 'widgets/brand_filter_bar.dart';
import 'widgets/fuel_filter_bar.dart';
import 'widgets/nearby_station_banner.dart';
import 'widgets/station_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

const _kClusterRadiusPx = 95.0;
const _kClusterMaxZoom = 12.0;

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _hasCenteredOnUser = false;
  bool _hasSetUserLocation = false;
  bool _hasTriggeredInitialPriceLoad = false;
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _priceDebounce;
  bool? _previousAllowMapRotation;

  // Station IDs currently rendered inside a cluster bubble. Populated by the
  // `MarkerClusterLayerOptions.builder` callback as it's invoked per cluster
  // during the library's render pass, and cleared in `_onMapEvent` so each
  // new camera state starts from a clean slate.
  final Set<String> _clusteredStationIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchLocation();
    });
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      setState(() => _searchQuery = query);
    });
    _searchFocus.addListener(() {
      setState(() => _isSearching = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _priceDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _centerOnUser() {
    final pos = context.read<LocationProvider>().position;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      // On web, programmatic moves don't reliably fire onPositionChanged,
      // so trigger a price load explicitly after the camera has settled.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onMapEvent(_mapController.camera, false);
      });
    }
  }

  Future<void> _requestLocation() async {
    final provider = context.read<LocationProvider>();
    await provider.fetchLocation();
    if (!mounted) return;

    final result = provider.lastResult;
    if (result == LocationResult.deniedForever) {
      await Geolocator.openAppSettings();
    } else if (result == LocationResult.serviceDisabled) {
      await Geolocator.openLocationSettings();
    }
  }

  void _selectSearchResult(Station station) {
    _searchController.clear();
    _searchFocus.unfocus();
    _mapController.move(LatLng(station.latitude, station.longitude), 15);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onMapEvent(_mapController.camera, false);
    });
    Navigator.pushNamed(context, AppRoutes.stationDetail, arguments: station);
  }

  void _onMapEvent(MapCamera camera, bool hasGesture) {
    // Invalidate cluster memberships from the previous camera state. The
    // rebuild that follows this event (on the next frame) will repopulate
    // `_clusteredStationIds` via the cluster `builder` callback, so by the
    // time the 500 ms debounce fires the set reflects the current render.
    //
    // flutter_map emits this callback synchronously from `moveRaw` BEFORE
    // scheduling the rebuild (see flutter_map's `map_controller_impl.dart`),
    // which makes clearing here safe.
    _clusteredStationIds.clear();
    _priceDebounce?.cancel();
    _priceDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final stationProvider = context.read<StationProvider>();
      final all = stationProvider.brandFilteredStations;
      if (all.isEmpty) return;

      final bounds = camera.visibleBounds;
      final visibleIds = <String>[];
      final unclusteredVisibleIds = <String>[];
      for (final s in all) {
        if (s.latitude < bounds.south || s.latitude > bounds.north) continue;
        if (s.longitude < bounds.west || s.longitude > bounds.east) continue;
        visibleIds.add(s.id);
        if (!_clusteredStationIds.contains(s.id)) {
          unclusteredVisibleIds.add(s.id);
        }
      }

      // If only a handful of stations are visible, just fetch for all of them
      // regardless of cluster state — every marker should show a price.
      // Otherwise fetch only for the individually-rendered (unclustered) ones,
      // since cluster bubbles never display prices.
      final ids = visibleIds.length <= 10 ? visibleIds : unclusteredVisibleIds;
      if (ids.isEmpty) return;
      stationProvider.loadPricesForStations(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final allowMapRotation = context.select<UserProvider, bool>(
      (provider) => provider.allowMapRotation,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_previousAllowMapRotation == true && !allowMapRotation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _mapController.camera.rotation == 0) return;
        _mapController.rotate(0);
      });
    }
    _previousAllowMapRotation = allowMapRotation;

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

    final filtered = stationProvider.brandFilteredStations;
    final bestStationId = stationProvider.bestMapStationId;

    if (filtered.isNotEmpty && !_hasTriggeredInitialPriceLoad) {
      _hasTriggeredInitialPriceLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _onMapEvent(_mapController.camera, false);
        } catch (_) {
          // Map controller not ready yet — the onMapReady nudge will cover it.
        }
      });
    }

    // Client-side search results.
    final searchResults = _searchQuery.isNotEmpty
        ? stationProvider.searchStations(_searchQuery)
        : <Station>[];

    final tileUrl = isDark
        ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final clusterColor = AppColors.primaryContainer(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GestureDetector(
            onTap: () {
              if (_isSearching) _searchFocus.unfocus();
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: AppConstants.defaultMapCenter,
                initialZoom: AppConstants.defaultMapZoom,
                interactionOptions: InteractionOptions(
                  flags: allowMapRotation
                      ? InteractiveFlag.all
                      : InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  // Nudge tiles to load — flutter_map may not render
                  // tiles when built behind a dialog or IndexedStack.
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (!mounted) return;
                    final cam = _mapController.camera;
                    _mapController.move(cam.center, cam.zoom + 0.001);
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (!mounted) return;
                      _mapController.move(cam.center, cam.zoom);
                    });
                  });
                },
                onTap: (_, _) {
                  if (_isSearching) _searchFocus.unfocus();
                },
                onPositionChanged: _onMapEvent,
                onLongPress: (_, point) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addStation,
                    arguments: point,
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
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
                            color: clusterColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: clusterColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: _kClusterRadiusPx.toInt(),
                    size: const Size(40, 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: _kClusterMaxZoom,
                    showPolygon: false,
                    markers: filtered.map((station) {
                      final price =
                          station.prices[stationProvider.selectedFuelType];
                      final isBest = station.id == bestStationId;
                      return Marker(
                        // Key on the outer Marker so `builder:` below can
                        // recover the station id for each clustered marker.
                        key: ValueKey(station.id),
                        point: LatLng(station.latitude, station.longitude),
                        width: 72,
                        height: 72,
                        child: StationMarker(
                          key: ValueKey(station.id),
                          station: station,
                          price: price,
                          isBestPrice: isBest,
                          isLoadingPrice: stationProvider.isPriceLoading(
                            station.id,
                          ),
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
                      // Record which stations are rendered inside this
                      // cluster bubble. The set is cleared on each map event
                      // (see `_onMapEvent`), so by the time the price-fetch
                      // debounce fires it holds the current clustered set.
                      for (final m in markers) {
                        final k = m.key;
                        if (k is ValueKey<String>) {
                          _clusteredStationIds.add(k.value);
                        }
                      }
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: clusterColor,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBackground
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: clusterColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : Colors.white,
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
          ),

          // Search bar
          Positioned(
            top: topPadding + 8,
            left: 16,
            right: 16,
            child: WebConstrained(
              child: GestureDetector(
                onTap: () => _searchFocus.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border(
                            context,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textMuted(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              style: AppTextStyles.body(context),
                              decoration: InputDecoration(
                                hintText: context.l10n.searchStations,
                                hintStyle: AppTextStyles.body(
                                  context,
                                ).copyWith(color: AppColors.textMuted(context)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                              },
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textMuted(context),
                              ),
                            )
                          else
                            const BrandFilterButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Fuel filter chips — below search bar
          Positioned(
            top: topPadding + 60,
            left: 0,
            right: 0,
            child: WebConstrained(child: FuelFilterBar()),
          ),

          // Nearby station prompt — below fuel filter bar
          Positioned(
            top: topPadding + 100,
            left: 16,
            right: 16,
            child: const NearbyStationBanner(),
          ),

          // Add Station button — bottom right, above locate button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 148,
            right: 16,
            child: _MapActionButton(
              icon: Icons.add_location_alt_outlined,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(context.l10n.addStationHintTitle),
                    content: Text(context.l10n.addStationHintBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.l10n.gotIt),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Locate button — bottom right, above the nav bar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 96,
            right: 16,
            child: _LocateButton(
              isLoading: locationProvider.isLoading,
              hasLocation: locationProvider.hasLocation,
              onPressed: locationProvider.isLoading
                  ? null
                  : locationProvider.hasLocation
                  ? _centerOnUser
                  : () => _requestLocation(),
            ),
          ),

          // Search results dropdown
          if (_isSearching &&
              _searchQuery.isNotEmpty &&
              searchResults.isNotEmpty)
            Positioned(
              top: topPadding + 60,
              left: 16,
              right: 16,
              child: WebConstrained(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: searchResults.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          indent: 56,
                          color: AppColors.border(context),
                        ),
                        itemBuilder: (context, index) {
                          final station = searchResults[index];
                          return _SearchResultTile(
                            station: station,
                            onTap: () => _selectSearchResult(station),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // "No results" message
          if (_isSearching && _searchQuery.isNotEmpty && searchResults.isEmpty)
            Positioned(
              top: topPadding + 60,
              left: 16,
              right: 16,
              child: WebConstrained(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border(context),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    context.l10n.noStationsFound(_searchQuery),
                    style: AppTextStyles.label(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;

  const _SearchResultTile({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            BrandLogo(brand: station.brand, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: AppTextStyles.bodyMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (station.city.isNotEmpty || station.address.isNotEmpty)
                    Text(
                      [
                        station.address,
                        station.city,
                      ].where((s) => s.isNotEmpty).join(', '),
                      style: AppTextStyles.meta(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppColors.textMuted(context),
            ),
          ],
        ),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryContainer(context),
                    ),
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

class _MapActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapActionButton({required this.icon, required this.onPressed});

  @override
  State<_MapActionButton> createState() => _MapActionButtonState();
}

class _MapActionButtonState extends State<_MapActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 20,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}
