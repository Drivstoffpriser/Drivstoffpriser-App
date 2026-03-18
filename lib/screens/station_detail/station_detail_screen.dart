import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../models/station.dart';
import '../../providers/price_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/price_card.dart';
import 'widgets/price_history_chart.dart';

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
      provider.loadReports(widget.station.id);
      provider.loadHistory(widget.station.id);
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final stationProvider = context.watch<StationProvider>();
    final priceProvider = context.watch<PriceProvider>();
    final prices = stationProvider.getPricesForStation(widget.station.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.station.name)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Station header info
          Row(
            children: [
              BrandLogo(brand: widget.station.brand, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.station.brand,
                      style: AppTextStyles.heading(isDark),
                    ),
                    if (widget.station.address.isNotEmpty || widget.station.city.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [widget.station.address, widget.station.city]
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          style: AppTextStyles.label(isDark),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirections(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.directions_outlined, size: 20),
                  label: const Text('Directions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.submitPrice,
                      arguments: widget.station,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Report Price'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Current Prices section
          Text('Current Prices', style: AppTextStyles.heading(isDark)),
          const SizedBox(height: 16),
          if (prices.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(isDark)),
              ),
              child: Text(
                'No prices reported yet.',
                style: AppTextStyles.muted(isDark),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...prices.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PriceCard(price: p),
                )),

          const SizedBox(height: 32),

          // Price History
          Text('Price History (30 days)', style: AppTextStyles.heading(isDark)),
          const SizedBox(height: 16),
          Skeletonizer(
            enabled: priceProvider.isLoadingHistory,
            child: priceProvider.isLoadingHistory
                ? Container(height: 220, color: Colors.white)
                : priceProvider.history.isNotEmpty
                    ? PriceHistoryChart(history: priceProvider.history)
                    : Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(isDark)),
                        ),
                        child: Text(
                          'No history available.',
                          style: AppTextStyles.muted(isDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
          ),

          const SizedBox(height: 32),

          // Recent Reports
          Text('Recent Reports', style: AppTextStyles.heading(isDark)),
          const SizedBox(height: 8),
          Skeletonizer(
            enabled: priceProvider.isLoading,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: priceProvider.isLoading ? 5 : priceProvider.reports.length.clamp(0, 10),
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                if (priceProvider.isLoading) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Container(height: 14, width: 100, color: Colors.white),
                    subtitle: Container(height: 10, width: 60, color: Colors.white),
                  );
                }

                final report = priceProvider.reports[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${report.fuelType.displayName}: ${report.price.toStringAsFixed(2)} kr',
                    style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    timeago.format(report.reportedAt),
                    style: AppTextStyles.label(isDark),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
