import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/fuel_type.dart';
import '../../../models/price_history_point.dart';

class PriceHistoryChart extends StatefulWidget {
  final Map<FuelType, List<PriceHistoryPoint>> history;

  const PriceHistoryChart({super.key, required this.history});

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  final Set<FuelType> _visible = {};

  static const _fuelColors = {
    FuelType.diesel: Colors.amber,
    FuelType.petrol95: Colors.blue,
    FuelType.petrol98: Colors.green,
    FuelType.electric: Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _visible.addAll(widget.history.keys);
  }

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If new fuel types appeared, show them
    for (final type in widget.history.keys) {
      if (!oldWidget.history.containsKey(type)) {
        _visible.add(type);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return const SizedBox.shrink();
    }

    // Compute the date range from the data
    DateTime? earliest;
    DateTime? latest;
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    for (final entry in widget.history.entries) {
      if (!_visible.contains(entry.key)) continue;
      for (final pt in entry.value) {
        if (earliest == null || pt.date.isBefore(earliest)) earliest = pt.date;
        if (latest == null || pt.date.isAfter(latest)) latest = pt.date;
        minPrice = min(minPrice, pt.price);
        maxPrice = max(maxPrice, pt.price);
      }
    }

    if (earliest == null || latest == null) {
      return const SizedBox.shrink();
    }

    final dateRange = latest.difference(earliest).inDays.toDouble();
    if (dateRange == 0) return const SizedBox.shrink();

    // Add some padding to the Y axis
    final yPad = (maxPrice - minPrice) * 0.15;
    final yMin = (minPrice - yPad).floorToDouble();
    final yMax = (maxPrice + yPad).ceilToDouble();

    final dateFormat = DateFormat('d/M');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: yMin,
              maxY: yMax,
              minX: 0,
              maxX: dateRange,
              gridData: FlGridData(
                horizontalInterval: ((yMax - yMin) / 4).ceilToDouble().clamp(1, 10),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 7,
                    getTitlesWidget: (value, _) {
                      final date = earliest!.add(Duration(days: value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dateFormat.format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, _) {
                      return Text(
                        '${value.toStringAsFixed(1)} kr',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final fuelType = widget.history.keys.where(
                        (k) => _visible.contains(k),
                      ).elementAt(spot.barIndex);
                      final date = earliest!.add(Duration(days: spot.x.toInt()));
                      return LineTooltipItem(
                        '${fuelType.displayName}\n${dateFormat.format(date)}: ${spot.y.toStringAsFixed(2)} kr',
                        TextStyle(
                          color: _fuelColors[fuelType] ?? Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: widget.history.entries
                  .where((e) => _visible.contains(e.key))
                  .map((entry) {
                final color = _fuelColors[entry.key] ?? Colors.grey;
                return LineChartBarData(
                  spots: entry.value.map((pt) {
                    final x = pt.date.difference(earliest!).inDays.toDouble();
                    return FlSpot(x, double.parse(pt.price.toStringAsFixed(2)));
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: color,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withAlpha(25),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: widget.history.keys.map((type) {
            final color = _fuelColors[type] ?? Colors.grey;
            final active = _visible.contains(type);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (active) {
                    // Don't allow hiding all lines
                    if (_visible.length > 1) _visible.remove(type);
                  } else {
                    _visible.add(type);
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: active ? color : color.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? null : Theme.of(context).colorScheme.outline,
                      decoration: active ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
