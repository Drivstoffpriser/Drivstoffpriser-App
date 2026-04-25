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

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
import '../../config/routes.dart';
import '../../models/station.dart';
import '../../providers/price_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/backend_api_client.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/loading_indicator.dart';
import 'edit_station_screen.dart';
import 'widgets/price_card.dart';
import 'widgets/price_history_chart.dart';
import '../submit_price/submit_price_screen.dart';

String _formatAge(BuildContext context, Duration age) {
  final minutes = age.inMinutes;
  final hours = age.inHours;
  if (minutes < 60) return context.l10n.ageMinutes(minutes);
  if (hours <= 23) return context.l10n.ageHours(hours);
  return context.l10n.ageOver1Day;
}

class StationDetailScreen extends StatefulWidget {
  final Station station;

  const StationDetailScreen({super.key, required this.station});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PriceProvider>();
      provider.clear();
      provider.loadHistory(widget.station.id);
      context.read<StationProvider>().loadPricesForStations([
        widget.station.id,
      ]);
    });
  }

  Future<void> _openDirections(BuildContext context) async {
    final lat = widget.station.latitude;
    final lng = widget.station.longitude;
    final label = Uri.encodeComponent(widget.station.name);

    final Uri uri;
    if (!kIsWeb && Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&q=$label');
    } else {
      uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallback = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteStation(StationProvider stationProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteStationTitle),
        content: Text(context.l10n.deleteStationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await BackendApiClient().deleteStation(widget.station.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.deleteStationFailed}: $e')),
        );
      }
      return;
    }
    if (mounted) {
      await stationProvider.refreshStations();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final priceProvider = context.watch<PriceProvider>();
    final userProvider = context.watch<UserProvider>();
    final station =
        stationProvider.getStation(widget.station.id) ?? widget.station;
    final prices = station.prices.values.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryContainer(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          // Hero header with station info
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.background(context),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [AppColors.darkSurfaceHigh, AppColors.darkBackground]
                        : [
                            AppColors.lightSurfaceLow,
                            AppColors.lightBackground,
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BrandLogo(brand: widget.station.brand, radius: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.station.name,
                                style: AppTextStyles.heading(context),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.station.address.isNotEmpty ||
                                  widget.station.city.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    widget.station.address,
                                    widget.station.city,
                                  ].where((s) => s.isNotEmpty).join(', '),
                                  style: AppTextStyles.meta(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Favorite button
              Consumer<StationProvider>(
                builder: (context, provider, _) {
                  final isFavorite = provider.isFavorite(widget.station.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : activeColor,
                    ),
                    onPressed: () => provider.toggleFavorite(widget.station.id),
                  );
                },
              ),
              if (userProvider.isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteStation(stationProvider),
                ),
              // Edit station button
              IconButton(
                icon: Icon(Icons.edit_outlined, color: activeColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditStationScreen(station: widget.station),
                    ),
                  );
                },
              ),
              // Navigate button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => _openDirections(context),
                  icon: Icon(Icons.directions_outlined, color: activeColor),
                  tooltip: context.l10n.navigate,
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ── Price Bento Grid ──
                Text(
                  context.l10n.currentPrices,
                  style: AppTextStyles.sectionHeader(context),
                ),
                const SizedBox(height: 12),
                if (prices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.noPricesReported,
                        style: AppTextStyles.label(context),
                      ),
                    ),
                  )
                else
                  _PriceBentoGrid(prices: prices),

                if (prices.any((p) => p.isEstimate)) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Stasjoner uten prishistorikk viser et estimat basert på andre stasjoner i området',
                    style: AppTextStyles.meta(context),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Report Price ──
                Text(
                  'Registrer pris',
                  style: AppTextStyles.sectionHeader(context),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _GradientActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Med kamera',
                        onPressed: () async {
                          final userProvider = context.read<UserProvider>();
                          if (!userProvider.isAuthenticated) {
                            await Navigator.pushNamed(context, AppRoutes.auth);
                            if (!context.mounted ||
                                !userProvider.isAuthenticated) {
                              return;
                            }
                          }
                          final priceProvider = context.read<PriceProvider>();
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.submitPrice,
                            arguments: widget.station,
                          );
                          if (context.mounted) {
                            priceProvider.loadHistory(widget.station.id);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradientActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Manuelt',
                        onPressed: () async {
                          final userProvider = context.read<UserProvider>();
                          if (!userProvider.isAuthenticated) {
                            await Navigator.pushNamed(context, AppRoutes.auth);
                            if (!context.mounted ||
                                !userProvider.isAuthenticated) {
                              return;
                            }
                          }
                          final priceProvider = context.read<PriceProvider>();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SubmitPriceScreen(station: widget.station),
                            ),
                          );
                          if (context.mounted) {
                            priceProvider.loadHistory(widget.station.id);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // ── Price History Chart ──
                Builder(
                  builder: (context) {
                    final distinctDates = priceProvider.history.values
                        .expand(
                          (list) => list.map(
                            (pt) =>
                                pt.date.toLocal().toString().substring(0, 10),
                          ),
                        )
                        .toSet();
                    if (!priceProvider.isLoadingHistory &&
                        distinctDates.length < 2) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        Text(
                          context.l10n.priceTrend,
                          style: AppTextStyles.sectionHeader(context),
                        ),
                        const SizedBox(height: 12),
                        if (priceProvider.isLoadingHistory)
                          const SizedBox(height: 220, child: LoadingIndicator())
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.border(context),
                                width: 0.5,
                              ),
                            ),
                            child: PriceHistoryChart(
                              history: priceProvider.history,
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── Recent Reports ──
                Text(
                  context.l10n.recentReports,
                  style: AppTextStyles.sectionHeader(context),
                ),
                const SizedBox(height: 12),
                if (priceProvider.isLoading)
                  const LoadingIndicator()
                else if (priceProvider.reports.isEmpty)
                  Text(
                    context.l10n.noReportsYet,
                    style: AppTextStyles.label(context),
                  )
                else
                  ...priceProvider.reports.take(10).map((report) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border(context),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: activeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 18,
                                color: activeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.fuelType.localizedName(context),
                                  style: AppTextStyles.bodyMedium(context),
                                ),
                                Text(
                                  _formatAge(
                                    context,
                                    DateTime.now().difference(
                                      report.reportedAt,
                                    ),
                                  ),
                                  style: AppTextStyles.meta(context),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${report.price.toStringAsFixed(2)} ${context.l10n.krSuffix}',
                            style: AppTextStyles.priceMedium(
                              context,
                            ).copyWith(color: activeColor),
                          ),
                          if (userProvider.isAdmin) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final provider = context.read<PriceProvider>();
                                final messenger = ScaffoldMessenger.of(context);
                                final l10n = context.l10n;
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(context.l10n.deleteReportTitle),
                                    content: Text(
                                      context.l10n.deleteReportBody,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(context.l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: Text(context.l10n.delete),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                try {
                                  await BackendApiClient()
                                      .deletePriceRegistration(
                                        widget.station.id,
                                        report.id,
                                      );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.deleteReportFailed(e.toString()),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                provider.loadHistory(widget.station.id);
                              },
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBentoGrid extends StatelessWidget {
  final List prices;

  const _PriceBentoGrid({required this.prices});

  @override
  Widget build(BuildContext context) {
    if (prices.length <= 2) {
      return Row(
        children: [
          for (int i = 0; i < prices.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: PriceCard(price: prices[i], compact: true)),
          ],
        ],
      );
    }

    // 3 or more: show all in one row with compact cards
    return Row(
      children: [
        for (int i = 0; i < prices.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: PriceCard(price: prices[i], compact: true)),
        ],
      ],
    );
  }
}

class _GradientActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_GradientActionButton> createState() => _GradientActionButtonState();
}

class _GradientActionButtonState extends State<_GradientActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF00d1ff), const Color(0xFF0091b3)]
                  : [const Color(0xFF0056b3), const Color(0xFF003f87)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF00d1ff) : const Color(0xFF0056b3))
                        .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: isDark ? AppColors.darkBackground : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
