import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/routes.dart';
import '../../../models/station.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/station_provider.dart';
import '../../../services/distance_service.dart';
import '../../../widgets/brand_logo.dart';

class StationBottomSheet extends StatelessWidget {
  const StationBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final sorted = stationProvider.sortedStations(
      userLat: locationProvider.position?.latitude,
      userLng: locationProvider.position?.longitude,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Sort toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${stationProvider.selectedFuelType.displayName} Prices',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    SegmentedButton<SortMode>(
                      segments: const [
                        ButtonSegment(value: SortMode.cheapest, label: Text('Cheapest')),
                        ButtonSegment(value: SortMode.nearest, label: Text('Nearest')),
                      ],
                      selected: {stationProvider.sortMode},
                      onSelectionChanged: (s) => stationProvider.setSortMode(s.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelSmall),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Station list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final station = sorted[index];
                    return _StationTile(station: station);
                  },
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
    final stationProvider = context.read<StationProvider>();
    final locationProvider = context.read<LocationProvider>();
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
      dense: true,
      leading: BrandLogo(brand: station.brand, radius: 18),
      title: Text(station.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          station.city,
          ?distanceStr,
          if (price != null) timeago.format(price.updatedAt),
        ].join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
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
        Navigator.pushNamed(context, AppRoutes.stationDetail, arguments: station);
      },
    );
  }
}
