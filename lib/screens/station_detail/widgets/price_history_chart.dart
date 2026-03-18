import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/fuel_type.dart';
import '../../../models/price_history_point.dart';
import '../../../providers/user_provider.dart';

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
  };

  @override
  void initState() {
    super.initState();
    _visible.addAll(widget.history.keys);
  }

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final type in widget.history.keys) {
      if (!oldWidget.history.containsKey(type)) {
        _visible.add(type);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) return const SizedBox.shrink();
    final isDark = context.watch<UserProvider>().isDarkMode;

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

    if (earliest == null || latest == null) return const SizedBox.shrink();

    final dateRange = latest.difference(earliest).inDays.toDouble();
    if (dateRange == 0) return const SizedBox.shrink();

    final yPad = (maxPrice - minPrice) * 0.15;
    final yMin = (minPrice - yPad).floorToDouble();
    final yMax = (maxPrice + yPad).ceilToDouble();

    final dateFormat = DateFormat('d/M');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(isDark)),
          ),
          child: LineChart(
            LineChartData(
              minY: yMin,
              maxY: yMax,
              minX: 0,
              maxX: dateRange,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: max(1, (yMax - yMin) / 4),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.border(isDark),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: max(1, dateRange / 3),
                    getTitlesWidget: (value, _) {
                      final date = earliest!.add(Duration(days: value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          dateFormat.format(date),
                          style: AppTextStyles.label(isDark).copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) {
                      return Text(
                        '${value.toStringAsFixed(1)}',
                        style: AppTextStyles.label(isDark).copyWith(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipColor: (_) => AppColors.surfaceElevated(isDark),
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final fuelType = widget.history.keys
                          .where((k) => _visible.contains(k))
                          .elementAt(spot.barIndex);
                      return LineTooltipItem(
                        '${fuelType.displayName}: ${spot.y.toStringAsFixed(2)}',
                        AppTextStyles.label(isDark).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: widget.history.entries
                  .where((e) => _visible.contains(e.key))
                  .map((entry) {
                return LineChartBarData(
                  spots: entry.value.map((pt) {
                    final x = pt.date.difference(earliest!).inDays.toDouble();
                    return FlSpot(x, pt.price);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.accent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.15),
                        AppColors.accent.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: widget.history.keys.map((type) {
            final active = _visible.contains(type);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (active) {
                    if (_visible.length > 1) _visible.remove(type);
                  } else {
                    _visible.add(type);
                  }
                });
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: active ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: active ? AppColors.accent.withOpacity(0.2) : AppColors.border(isDark),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.textMuted(isDark),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type.displayName,
                        style: AppTextStyles.label(isDark).copyWith(
                          color: active ? AppColors.textPrimary(isDark) : AppColors.textMuted(isDark),
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
