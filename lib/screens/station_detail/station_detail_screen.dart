import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../models/station.dart';
import '../../providers/price_provider.dart';
import '../../providers/station_provider.dart';
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
    final stationProvider = context.watch<StationProvider>();
    final priceProvider = context.watch<PriceProvider>();
    final prices = stationProvider.getPricesForStation(widget.station.id);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text(widget.station.name, style: AppTextStyles.title(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                BrandLogo(brand: widget.station.brand, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.brand,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                      if (widget.station.address.isNotEmpty ||
                          widget.station.city.isNotEmpty) ...[
                        const SizedBox(height: 2),
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
          const SizedBox(height: 16),
          _PressableButton(
            onPressed: () => _openDirections(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Directions',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Current Prices', style: AppTextStyles.title(context)),
          const SizedBox(height: 12),
          if (prices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No prices reported yet.',
                style: AppTextStyles.label(context),
              ),
            )
          else
            ...prices.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PriceCard(price: p),
              ),
            ),
          const SizedBox(height: 24),
          Text('Price History (30 days)', style: AppTextStyles.title(context)),
          const SizedBox(height: 12),
          if (priceProvider.isLoadingHistory)
            const SizedBox(height: 220, child: LoadingIndicator())
          else if (priceProvider.history.isNotEmpty)
            PriceHistoryChart(history: priceProvider.history),
          const SizedBox(height: 24),
          _PressableButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.submitPrice,
                arguments: widget.station,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 20, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Report a Price',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: const Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent Reports', style: AppTextStyles.title(context)),
          const SizedBox(height: 12),
          if (priceProvider.isLoading)
            const LoadingIndicator()
          else if (priceProvider.reports.isEmpty)
            Text('No reports yet.', style: AppTextStyles.label(context))
          else
            ...priceProvider.reports.take(10).map((report) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: AppColors.textMuted(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report.fuelType.displayName}: ${report.price.toStringAsFixed(2)} kr',
                            style: AppTextStyles.bodyMedium(context),
                          ),
                          Text(
                            timeago.format(report.reportedAt),
                            style: AppTextStyles.meta(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _PressableButton({required this.onPressed, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
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
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: widget.child,
        ),
      ),
    );
  }
}
