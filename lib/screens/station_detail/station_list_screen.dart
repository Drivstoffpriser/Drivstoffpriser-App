import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../services/distance_service.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/loading_indicator.dart';
import '../map/widgets/brand_filter_bar.dart';
import '../map/widgets/fuel_filter_bar.dart';

class StationListScreen extends StatelessWidget {
  const StationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final sorted = stationProvider.sortedStations(
      userLat: locationProvider.position?.latitude,
      userLng: locationProvider.position?.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations'),
      ),
      body: Column(
        children: [
          const FuelFilterBar(
            trailing: BrandFilterButton(heroTag: 'brandFilterList'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${sorted.length} stations', style: Theme.of(context).textTheme.bodySmall),
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
                ),
              ],
            ),
          ),
          Expanded(
            child: stationProvider.isLoading
                ? const LoadingIndicator()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final station = sorted[index];
                      final price = stationProvider.getPriceForStation(station.id);

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

                      return ListTile(
                        leading: BrandLogo(brand: station.brand),
                        title: Text(station.name),
                        subtitle: Text(
                          [
                            if (station.city.isNotEmpty) station.city,
                            ?distanceStr,
                            if (price != null) timeago.format(price.updatedAt),
                          ].join(' · '),
                        ),
                        trailing: price != null
                            ? Text(
                                '${price.price.toStringAsFixed(2)} kr',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.stationDetail,
                            arguments: station,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
