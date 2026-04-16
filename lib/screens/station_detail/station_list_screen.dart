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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
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
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.l10n.navStations,
          style: AppTextStyles.title(context),
        ),
      ),
      body: Column(
        children: [
          FuelFilterBar(
            trailing: const BrandFilterButton(
              heroTag: 'brandFilterList',
              filterLocation: FilterLocation.list,
            ),
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
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.sortLabel(
                          switch (stationProvider.sortMode) {
                            SortMode.cheapest => context.l10n.sortCheapest,
                            SortMode.nearest => context.l10n.sortNearest,
                            SortMode.latest => context.l10n.sortLatest,
                          },
                        ),
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
            child:
                (stationProvider.isLoading || stationProvider.isListLoading) &&
                    sorted.isEmpty
                ? const LoadingIndicator()
                : RefreshIndicator(
                    onRefresh: () async {
                      try {
                        await stationProvider.loadSortedStations();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.stationsRefreshed),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.refreshFailed)),
                          );
                        }
                      }
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final station = sorted[index];
                        final price =
                            station.prices[stationProvider.selectedFuelType];

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
                          stationId: station.id,
                          name: station.name,
                          brand: station.brand,
                          city: station.city,
                          distance: distanceStr,
                          price: price?.price,
                          lastUpdated: price?.updatedAt,
                          isEstimate: price?.isEstimate ?? false,
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
          ),
        ],
      ),
    );
  }
}

class _StationListTile extends StatefulWidget {
  final String stationId;
  final String name;
  final String brand;
  final String city;
  final String? distance;
  final double? price;
  final DateTime? lastUpdated;
  final bool isEstimate;
  final VoidCallback onTap;

  const _StationListTile({
    required this.stationId,
    required this.name,
    required this.brand,
    required this.city,
    this.distance,
    this.price,
    this.lastUpdated,
    this.isEstimate = false,
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
                      Text.rich(
                        TextSpan(
                          style: AppTextStyles.meta(context),
                          children: [
                            if (widget.city.isNotEmpty)
                              TextSpan(text: widget.city),
                            if (widget.city.isNotEmpty &&
                                (widget.distance != null ||
                                    widget.lastUpdated != null ||
                                    widget.isEstimate))
                              const TextSpan(text: ' · '),
                            if (widget.distance != null)
                              TextSpan(text: widget.distance),
                            if (widget.distance != null &&
                                (widget.lastUpdated != null ||
                                    widget.isEstimate))
                              const TextSpan(text: ' · '),
                            if (widget.isEstimate)
                              TextSpan(
                                text: 'Estimat',
                                style: TextStyle(color: Colors.orange),
                              )
                            else if (widget.lastUpdated != null)
                              TextSpan(
                                text: timeago.format(
                                  widget.lastUpdated!,
                                  locale: Localizations.localeOf(
                                    context,
                                  ).languageCode,
                                ),
                                style: TextStyle(
                                  color: AppColors.freshness(
                                    DateTime.now().difference(
                                      widget.lastUpdated!,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
                const SizedBox(width: 8),
                Consumer<StationProvider>(
                  builder: (context, provider, _) {
                    final isFavorite = provider.isFavorite(widget.stationId);
                    return GestureDetector(
                      onTap: () => provider.toggleFavorite(widget.stationId),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFavorite
                            ? Colors.red
                            : AppColors.textMuted(context),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
