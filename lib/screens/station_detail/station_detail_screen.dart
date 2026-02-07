import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final priceProvider = context.watch<PriceProvider>();
    final prices = stationProvider.getPricesForStation(widget.station.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.station.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Station info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BrandLogo(brand: widget.station.brand),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.station.brand,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (widget.station.address.isNotEmpty ||
                                widget.station.city.isNotEmpty)
                              Text(
                                [
                                  widget.station.address,
                                  widget.station.city,
                                ].where((s) => s.isNotEmpty).join(', '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prices
          Text('Current Prices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (prices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No prices reported yet.'),
              ),
            )
          else
            ...prices.map((p) => PriceCard(price: p)),

          const SizedBox(height: 24),

          // Price history chart
          Text('Price History (30 days)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (priceProvider.isLoadingHistory)
            const SizedBox(height: 220, child: LoadingIndicator())
          else if (priceProvider.history.isNotEmpty)
            PriceHistoryChart(history: priceProvider.history),

          const SizedBox(height: 24),

          // Report button
          FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.submitPrice,
                arguments: widget.station,
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Report a Price'),
          ),

          const SizedBox(height: 24),

          // Recent reports
          Text('Recent Reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (priceProvider.isLoading)
            const LoadingIndicator()
          else if (priceProvider.reports.isEmpty)
            const Text('No reports yet.')
          else
            ...priceProvider.reports.take(10).map((report) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long, size: 20),
                title: Text(
                  '${report.fuelType.displayName}: ${report.price.toStringAsFixed(2)} kr',
                ),
                subtitle: Text(timeago.format(report.reportedAt)),
              );
            }),
        ],
      ),
    );
  }
}
