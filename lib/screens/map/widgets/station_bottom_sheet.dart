import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../l10n/l10n_helper.dart';
import '../../../config/routes.dart';
import '../../../models/station.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/station_provider.dart';
import '../../../services/distance_service.dart';
import '../../../widgets/brand_logo.dart';

class StationBottomSheet extends StatefulWidget {
  final DraggableScrollableController? sheetController;

  const StationBottomSheet({super.key, this.sheetController});

  @override
  State<StationBottomSheet> createState() => _StationBottomSheetState();
}

class _StationBottomSheetState extends State<StationBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );

    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sorted = stationProvider.sortedStations(
      userLat: locationProvider.position?.latitude,
      userLng: locationProvider.position?.longitude,
    );

    return DraggableScrollableSheet(
      controller: widget.sheetController,
      initialChildSize: 0.25,
      minChildSize: 0.08,
      maxChildSize: 0.7,
      snap: true,
      snapSizes: const [0.25, 0.5],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                        : const Color(0xFFDDE1E6),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          context.l10n.bestNearby,
                          style: AppTextStyles.title(context),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer(context)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stationProvider.selectedFuelType.localizedName(context),
                            style: AppTextStyles.label(context).copyWith(
                              color: AppColors.primaryContainer(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                context.l10n.sortLabel(switch (stationProvider.sortMode) {
                                  SortMode.cheapest => context.l10n.sortCheapest,
                                  SortMode.nearest => context.l10n.sortNearest,
                                  SortMode.latest => context.l10n.sortLatest,
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
                  const SizedBox(height: 8),
                  Expanded(
                    child: FadeTransition(
                      opacity: _contentOpacity,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: sorted.isEmpty
                            ? Center(
                                child: Text(
                                  context.l10n.noPricesReported,
                                  style: AppTextStyles.label(context),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).padding.bottom +
                                          100,
                                ),
                                itemCount: sorted.length,
                                itemBuilder: (context, index) =>
                                    _StationTile(station: sorted[index]),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StationTile extends StatefulWidget {
  final Station station;

  const _StationTile({required this.station});

  @override
  State<_StationTile> createState() => _StationTileState();
}

class _StationTileState extends State<_StationTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.read<StationProvider>();
    final locationProvider = context.read<LocationProvider>();
    final price = stationProvider.getPriceForStation(widget.station.id);

    String? distanceStr;
    if (locationProvider.hasLocation) {
      final meters = DistanceService.distanceInMeters(
        locationProvider.position!.latitude,
        locationProvider.position!.longitude,
        widget.station.latitude,
        widget.station.longitude,
      );
      distanceStr = DistanceService.formatDistance(meters);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.pushNamed(
          context,
          AppRoutes.stationDetail,
          arguments: widget.station,
        );
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
                BrandLogo(brand: widget.station.brand, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: AppTextStyles.stationName(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (widget.station.city.isNotEmpty)
                            widget.station.city,
                          ?distanceStr,
                          if (price != null) timeago.format(price.updatedAt),
                        ].join(' · '),
                        style: AppTextStyles.meta(context),
                      ),
                    ],
                  ),
                ),
                if (price != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${price.price.toStringAsFixed(2)} ${context.l10n.krSuffix}',
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
