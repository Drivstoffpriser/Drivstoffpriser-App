import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:skeletonizer/skeletonizer.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/distance_service.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/price_badge.dart';
import '../map/widgets/brand_filter_bar.dart';
import '../map/widgets/fuel_filter_bar.dart';

class StationListScreen extends StatelessWidget {
  const StationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final stations = stationProvider.sortedStations(
      userLat: locationProvider.position?.latitude,
      userLng: locationProvider.position?.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FuelFilterBar(
            trailing: BrandFilterButton(heroTag: 'brandFilterList'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  '${stations.length} stations found',
                  style: AppTextStyles.label(isDark),
                ),
                const Spacer(),
                PopupMenuButton<SortMode>(
                  initialValue: stationProvider.sortMode,
                  onSelected: stationProvider.setSortMode,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: SortMode.cheapest, child: Text('Cheapest')),
                    PopupMenuItem(value: SortMode.nearest, child: Text('Nearest')),
                    PopupMenuItem(value: SortMode.latest, child: Text('Latest')),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sort: ${stationProvider.sortMode.name[0].toUpperCase()}${stationProvider.sortMode.name.substring(1)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                _SortSegmentedButton(
                  isDark: isDark,
                  selected: stationProvider.sortMode,
                  onChanged: stationProvider.setSortMode,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Skeletonizer(
                  key: ValueKey(
                    '${stationProvider.selectedFuelType}_${stationProvider.isLoading}',
                  ),
                  enabled: stationProvider.isLoading,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: stationProvider.isLoading ? 10 : stations.length,
                    separatorBuilder: (_, __) => const SizedBox.shrink(),
                    itemBuilder: (context, index) {
                      if (stationProvider.isLoading) {
                        return _StationListTileSkeleton(isDark: isDark);
                      }

                      final station = stations[index];
                      final price = stationProvider.getPriceForStation(
                        station.id,
                      );

                      String? distanceStr;
                      if (locationProvider.hasLocation) {
                        final meters = DistanceService.distanceInMeters(
                          locationProvider.position!.latitude,
                          locationProvider.position!.longitude,
                          station.latitude,
                          station.longitude,
                        );
                        distanceStr = DistanceService.formatDistance(meters);
                      }

                      return TweenAnimationBuilder<double>(
                        duration: Duration(
                          milliseconds: 180 + (index * 40).clamp(0, 400),
                        ),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.stationDetail,
                                  arguments: station,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    // Price
                                    if (price != null)
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          price.price.toStringAsFixed(2),
                                          style: AppTextStyles.price(isDark)
                                              .copyWith(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 8),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            station.name,
                                            style: AppTextStyles.body(isDark)
                                                .copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (station.city.isNotEmpty)
                                                station.city,
                                              if (distanceStr != null)
                                                distanceStr,
                                              if (price != null)
                                                timeago.format(price.updatedAt),
                                            ].join(' · '),
                                            style: AppTextStyles.label(isDark)
                                                .copyWith(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Opacity(
                                      opacity: 0.8,
                                      child: BrandLogo(
                                        brand: station.brand,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortSegmentedButton extends StatelessWidget {
  final bool isDark;
  final SortMode selected;
  final Function(SortMode) onChanged;

  const _SortSegmentedButton({
    required this.isDark,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(SortMode.cheapest, 'Cheapest'),
          _buildSegment(SortMode.nearest, 'Nearest'),
        ],
      ),
    );
  }

  Widget _buildSegment(SortMode mode, String label) {
    final isSelected = selected == mode;
    return GestureDetector(
      onTap: () => onChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.label(isDark).copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary(isDark),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _StationListTileSkeleton extends StatelessWidget {
  final bool isDark;
  const _StationListTileSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const CircleAvatar(radius: 20),
      title: Container(height: 16, width: 120, color: Colors.white),
      subtitle: Container(height: 12, width: 80, color: Colors.white),
      trailing: Container(height: 32, width: 64, color: Colors.white),
    );
  }
}
