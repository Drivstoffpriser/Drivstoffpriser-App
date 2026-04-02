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

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../l10n/l10n_helper.dart';
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
  List<LineBarSpot>? _touchedSpots;

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

  Color _fuelColor(FuelType type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case FuelType.diesel:
        return isDark ? const Color(0xFFffd166) : Colors.amber;
      case FuelType.petrol95:
        return isDark ? const Color(0xFF00d1ff) : const Color(0xFF0056b3);
      case FuelType.petrol98:
        return isDark ? const Color(0xFF6fddaa) : const Color(0xFF006e25);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return const SizedBox.shrink();
    }

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

    final yPad = (maxPrice - minPrice) * 0.15;
    final yMin = (minPrice - yPad).floorToDouble();
    final yMax = (maxPrice + yPad).ceilToDouble();

    final dateFormat = DateFormat('d/M');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = AppColors.border(context).withValues(alpha: 0.3);
    final labelColor = AppColors.textMuted(context);

    final visibleFuelTypes = widget.history.keys
        .where((k) => _visible.contains(k))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              LineChart(
                LineChartData(
                  minY: yMin,
                  maxY: yMax,
                  minX: 0,
                  maxX: dateRange,
                  gridData: FlGridData(
                    horizontalInterval: ((yMax - yMin) / 4)
                        .ceilToDouble()
                        .clamp(1, 10),
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: gridColor, strokeWidth: 0.5),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: gridColor, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, _) {
                          final date = earliest!.add(
                            Duration(days: value.toInt()),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dateFormat.format(date),
                              style: TextStyle(fontSize: 10, color: labelColor),
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
                            '${value.toStringAsFixed(1)} ${context.l10n.krSuffix}',
                            style: TextStyle(fontSize: 10, color: labelColor),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.lineBarSpots != null &&
                            response!.lineBarSpots!.isNotEmpty) {
                          _touchedSpots = response.lineBarSpots;
                        } else if (event is FlLongPressEnd ||
                            event is FlPanEndEvent ||
                            event is FlTapUpEvent) {
                          _touchedSpots = null;
                        }
                      });
                    },
                    touchTooltipData: LineTouchTooltipData(
                      // Hide the built-in tooltip — we draw our own
                      getTooltipColor: (_) => Colors.transparent,
                      getTooltipItems: (spots) =>
                          spots.map((_) => null).toList(),
                    ),
                  ),
                  lineBarsData: widget.history.entries
                      .where((e) => _visible.contains(e.key))
                      .map((entry) {
                        final color = _fuelColor(entry.key, context);
                        return LineChartBarData(
                          spots: entry.value.map((pt) {
                            final x = pt.date
                                .difference(earliest!)
                                .inDays
                                .toDouble();
                            return FlSpot(
                              x,
                              double.parse(pt.price.toStringAsFixed(2)),
                            );
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: color,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              final isTouched =
                                  _touchedSpots?.any(
                                    (s) => s.x == spot.x && s.y == spot.y,
                                  ) ??
                                  false;
                              return FlDotCirclePainter(
                                radius: isTouched ? 5 : 0,
                                color: color,
                                strokeWidth: isTouched ? 2 : 0,
                                strokeColor: isDark
                                    ? AppColors.darkBackground
                                    : Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withAlpha(25),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
              // Static tooltip overlay — top-left inside chart
              if (_touchedSpots != null && _touchedSpots!.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 44, // right of the y-axis labels
                  child: _buildStaticTooltip(
                    earliest,
                    dateFormat,
                    isDark,
                    visibleFuelTypes,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: widget.history.keys.map((type) {
            final color = _fuelColor(type, context);
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
                    type.localizedName(context),
                    style: TextStyle(
                      fontSize: 12,
                      color: active
                          ? AppColors.textPrimary(context)
                          : AppColors.textMuted(context),
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

  Widget _buildStaticTooltip(
    DateTime earliest,
    DateFormat dateFormat,
    bool isDark,
    List<FuelType> visibleFuelTypes,
  ) {
    final spots = _touchedSpots!;
    final date = earliest.add(Duration(days: spots.first.x.toInt()));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceHighest : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateFormat.format(date),
            style: AppTextStyles.meta(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          for (final spot in spots)
            if (spot.barIndex < visibleFuelTypes.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _fuelColor(
                          visibleFuelTypes[spot.barIndex],
                          context,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${visibleFuelTypes[spot.barIndex].localizedName(context)}: ${spot.y.toStringAsFixed(2)} ${context.l10n.krSuffix}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _fuelColor(
                          visibleFuelTypes[spot.barIndex],
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
