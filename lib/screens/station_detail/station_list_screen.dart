import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
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

    final userProvider = context.watch<UserProvider>();

    // Default to Best For You if vehicle data is available and no sort mode is set yet (or it's still the initial default)
    if (userProvider.hasVehicleData && stationProvider.sortMode == SortMode.cheapest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (stationProvider.sortMode == SortMode.cheapest) {
          stationProvider.setSortMode(SortMode.bestForYou);
        }
      });
    }

    final sorted = stationProvider.sortedStations(
      userLat: locationProvider.position?.latitude,
      userLng: locationProvider.position?.longitude,
      tankSize: userProvider.tankSize,
      consumptionPer100km: userProvider.consumptionPer100km,
    );

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text(context.l10n.navStations, style: AppTextStyles.title(context)),
      ),
      body: Column(
        children: [
          FuelFilterBar(
            trailing: const BrandFilterButton(heroTag: 'brandFilterList'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  context.l10n.stationsCount(sorted.length),
                  style: AppTextStyles.label(context),
                ),
                const Spacer(),
                PopupMenuButton<SortMode>(
                  initialValue: stationProvider.sortMode,
                  onSelected: stationProvider.setSortMode,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: SortMode.cheapest,
                      child: Text(ctx.l10n.sortCheapest),
                    ),
                    PopupMenuItem(
                      value: SortMode.nearest,
                      child: Text(ctx.l10n.sortNearest),
                    ),
                    PopupMenuItem(
                      value: SortMode.latest,
                      child: Text(ctx.l10n.sortLatest),
                    ),
                    PopupMenuItem(
                      value: SortMode.bestForYou,
                      child: Text(context.l10n.sortBestForYou),
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.sortLabel(switch (stationProvider.sortMode) {
                          SortMode.cheapest => context.l10n.sortCheapest,
                          SortMode.nearest => context.l10n.sortNearest,
                          SortMode.latest => context.l10n.sortLatest,
                          SortMode.bestForYou => context.l10n.sortBestForYou,
                        }),
                        style: AppTextStyles.label(context),
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
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 100,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final station = sorted[index];
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

                      return _StationListTile(
                        name: station.name,
                        brand: station.brand,
                        city: station.city,
                        distance: distanceStr,
                        price: price?.price,
                        lastUpdated: price?.updatedAt,
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

class _StationListTile extends StatefulWidget {
  final String name;
  final String brand;
  final String city;
  final String? distance;
  final double? price;
  final DateTime? lastUpdated;
  final VoidCallback onTap;

  const _StationListTile({
    required this.name,
    required this.brand,
    required this.city,
    this.distance,
    this.price,
    this.lastUpdated,
    required this.onTap,
  });

  @override
  State<_StationListTile> createState() => _StationListTileState();
}

class _StationListTileState extends State<_StationListTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                BrandLogo(brand: widget.brand, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: AppTextStyles.stationName(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (widget.city.isNotEmpty) widget.city,
                          if (widget.distance != null) widget.distance,
                          if (widget.lastUpdated != null)
                            timeago.format(widget.lastUpdated!),
                        ].join(' · '),
                        style: AppTextStyles.meta(context),
                      ),
                    ],
                  ),
                ),
                if (widget.price != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${widget.price!.toStringAsFixed(2)} ${context.l10n.krSuffix}',
                    style: AppTextStyles.priceLarge(
                      context,
                    ).copyWith(color: AppColors.primaryContainer(context)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
