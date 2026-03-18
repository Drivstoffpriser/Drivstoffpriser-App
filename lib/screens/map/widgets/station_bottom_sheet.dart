import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../config/routes.dart';
import '../../../models/station.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/station_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/distance_service.dart';
import '../../../widgets/brand_logo.dart';
import '../../../widgets/price_badge.dart';

class StationBottomSheet extends StatelessWidget {
  final DraggableScrollableController? sheetController;

  const StationBottomSheet({super.key, this.sheetController});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final stations = stationProvider.sortedStations(
      userLat: locationProvider.position?.latitude,
      userLng: locationProvider.position?.longitude,
    );

    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.25,
      minChildSize: 0.08,
      maxChildSize: 0.55,
      snap: true,
      snapSizes: const [0.25, 0.5],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border(isDark),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
<<<<<<< HEAD
                            '${stationProvider.selectedFuelType.displayName} Prices',
                            style: Theme.of(context).textTheme.titleSmall,
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
=======
                            '${stationProvider.selectedFuelType.displayName} nearby',
                            style: AppTextStyles.heading(isDark),
>>>>>>> 2bd3d39 (ui overhaul)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (stationProvider.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Skeletonizer(
                      enabled: true,
                      child: _StationTile(station: Station.empty()),
                    ),
                    childCount: 5,
                  ),
                )
              else if (stations.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No stations found in this area',
                      style: AppTextStyles.muted(isDark),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _StationTile(station: stations[index]),
                      childCount: stations.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StationTile extends StatelessWidget {
  final Station station;

  const _StationTile({required this.station});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final stationProvider = context.read<StationProvider>();
    final locationProvider = context.read<LocationProvider>();
    final price = stationProvider.getPriceForStation(station.id);

    String? distanceStr;
    if (locationProvider.hasLocation && station.id.isNotEmpty) {
      final meters = DistanceService.distanceInMeters(
        locationProvider.position!.latitude,
        locationProvider.position!.longitude,
        station.latitude,
        station.longitude,
      );
      distanceStr = DistanceService.formatDistance(meters);
    }

    return InkWell(
      onTap: station.id.isEmpty
          ? null
          : () {
              Navigator.pushNamed(
                context,
                AppRoutes.stationDetail,
                arguments: station,
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Price - dominant leading element
            if (price != null)
              SizedBox(
                width: 80,
                child: Text(
                  price.price.toStringAsFixed(2),
                  style: AppTextStyles.price(
                    isDark,
                  ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              )
            else
              const SizedBox(width: 8),

            // Station Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: AppTextStyles.body(
                      isDark,
                    ).copyWith(fontWeight: FontWeight.w500, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (station.city.isNotEmpty) station.city,
                      if (distanceStr != null) distanceStr,
                      if (price != null) timeago.format(price.updatedAt),
                    ].join(' · '),
                    style: AppTextStyles.label(isDark).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary(isDark).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Brand Logo - small and muted
            Opacity(
              opacity: 0.8,
              child: BrandLogo(brand: station.brand, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
