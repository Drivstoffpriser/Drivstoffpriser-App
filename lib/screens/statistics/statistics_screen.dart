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
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_sizes.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/fuel_type.dart';
import '../../models/price_statistics.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../config/routes.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  LocationProvider? _locationProvider;
  bool _hadLocation = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _locationProvider = context.read<LocationProvider>();
      _locationProvider!.addListener(_onLocationChanged);
      _fetchStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationProvider?.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (!_hadLocation && (_locationProvider?.position != null)) {
      _hadLocation = true;
      _fetchStatistics();
    }
  }

  void _fetchStatistics() {
    final location = context.read<LocationProvider>();
    final stations = context.read<StationProvider>();
    final position = location.position;
    _hadLocation = position != null;

    final statisticsProvider = context.read<StatisticsProvider>();
    statisticsProvider.fetchStatistics(
      lat: position?.latitude,
      lng: position?.longitude,
      radiusKm: stations.listRadiusKm,
    );
    statisticsProvider.fetchProviderPrices(refresh: true);
    statisticsProvider.fetchContributors(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatisticsProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              context.l10n.statisticsTitle,
              style: AppTextStyles.title(context),
            ),
            actions: [
              if (provider.isRefreshing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.space4),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (!provider.isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchStatistics,
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: context.l10n.statisticsTabPriser),
                Tab(text: context.l10n.statisticsTabKjeder),
                Tab(text: context.l10n.statisticsTabRapporter),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _tabController,
              builder: (context, _) => Column(
                children: [
                  Offstage(
                    offstage: _tabController.index != 0,
                    child: _PriserTab(
                      provider: provider,
                      onRefresh: _fetchStatistics,
                    ),
                  ),
                  Offstage(
                    offstage: _tabController.index != 1,
                    child: _KjederTab(provider: provider),
                  ),
                  Offstage(
                    offstage: _tabController.index != 2,
                    child: _RapporterTab(
                      provider: provider,
                      onRefresh: _fetchStatistics,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Priser tab
// ---------------------------------------------------------------------------

class _PriserTab extends StatefulWidget {
  final StatisticsProvider provider;
  final VoidCallback onRefresh;

  const _PriserTab({required this.provider, required this.onRefresh});

  @override
  State<_PriserTab> createState() => _PriserTabState();
}

class _PriserTabState extends State<_PriserTab> {
  bool _showNearby = false;
  static const _steps = [5, 10, 20, 50, 100, 200, 500, null];
  int? _draggingIndex;

  static String _radiusLabel(BuildContext context, double? km) {
    if (km == null) return context.l10n.allOfNorway;
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.round()} km';
  }

  int _indexForKm(double? km) {
    if (km == null) return _steps.length - 1;
    final idx = _steps.indexWhere((s) => s != null && (s as num) >= km.round());
    return idx == -1 ? _steps.length - 1 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final hasLocation = locationProvider.position != null;
    final committedKm = stationProvider.listRadiusKm;

    final listPadding = EdgeInsets.only(
      left: AppSizes.screenPadding,
      right: AppSizes.screenPadding,
      top: AppSizes.space4,
      bottom: bottomPadding + AppSizes.space8 * 3,
    );

    if (provider.error != null && provider.statistics == null) {
      return Padding(
        padding: listPadding,
        child: Text(
          provider.error!,
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
      );
    }

    final isLoading = provider.isLoading || provider.isRefreshing;
    final stats = provider.statistics;
    final extremes = (isLoading || stats == null)
        ? const <FuelType, PriceExtremes>{}
        : (_showNearby
              ? stats.nearbyStationsExtremes
              : stats.allStationsExtremes);

    final activeColor = AppColors.primaryContainer(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayIndex = _draggingIndex ?? _indexForKm(committedKm);
    final displayKm = _steps[displayIndex]?.toDouble();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: listPadding,
      children: [
        // Filter toggle
        Row(
          children: [
            _ToggleBtn(
              label: context.l10n.statisticsFilterAll,
              isActive: !_showNearby,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () => setState(() => _showNearby = false),
            ),
            const SizedBox(width: AppSizes.space2),
            _ToggleBtn(
              label: context.l10n.statisticsFilterNearby,
              isActive: _showNearby,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () => setState(() => _showNearby = true),
            ),
          ],
        ),

        // Radius slider (only when nearby is active)
        if (_showNearby) ...[
          const SizedBox(height: AppSizes.space3),
          Row(
            children: [
              Text(
                context.l10n.searchRadius,
                style: AppTextStyles.bodyMedium(context),
              ),
              const Spacer(),
              Text(
                _radiusLabel(context, displayKm),
                style: AppTextStyles.label(context),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: AppColors.border(context),
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: displayIndex.toDouble(),
              min: 0,
              max: (_steps.length - 1).toDouble(),
              divisions: _steps.length - 1,
              onChanged: (v) {
                setState(() => _draggingIndex = v.round());
              },
              onChangeEnd: (v) {
                final idx = v.round();
                final km = _steps[idx]?.toDouble();
                setState(() => _draggingIndex = null);
                final pos = locationProvider.position;
                stationProvider.setListRadius(
                  km,
                  userLat: pos?.latitude,
                  userLng: pos?.longitude,
                );
                widget.onRefresh();
              },
            ),
          ),
        ],

        const SizedBox(height: AppSizes.space4),

        // Content
        if (!isLoading && _showNearby && !hasLocation)
          _NoLocationCard()
        else if (!isLoading &&
            _showNearby &&
            (stats?.nearbyStationsExtremes.isEmpty ?? true))
          _NoLocationCard()
        else
          _ExtremesCard(extremes: extremes, isLoading: isLoading),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kjeder tab
// ---------------------------------------------------------------------------

// Human-readable names for backend provider keys.
const _providerDisplayNames = {
  'AUTOMAT_1': 'Automat 1',
  'BEST': 'Best',
  'BUNKER_OIL': 'Bunker Oil',
  'CIRCLE_K': 'Circle K',
  'DRIV': 'Driv',
  'ESSO': 'Esso',
  'HALTBAKK_EXPRESS': 'Haltbakk Express',
  'OLJELEVERANDØREN': 'Oljeleverandøren',
  'ST1': 'ST1',
  'TANKEN': 'Tanken',
  'TRONDER_OIL': 'Trønder Oil',
  'UNO_X': 'Uno-X',
  'YX': 'YX',
  'YX_TRUCK': 'YX Truck',
};

String _providerName(String key) =>
    _providerDisplayNames[key] ?? key.replaceAll('_', ' ');

class _KjederTab extends StatefulWidget {
  final StatisticsProvider provider;

  const _KjederTab({required this.provider});

  @override
  State<_KjederTab> createState() => _KjederTabState();
}

class _KjederTabState extends State<_KjederTab> {
  FuelType _selectedFuelType = FuelType.petrol95;
  Set<String> _hiddenProviders = {};
  List<LineBarSpot>? _touchedSpots;
  bool _show24h = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.provider.fetchProviderPrices();
    });
  }

  Color _colorForIndex(int index) =>
      AppColors.providerChartColors[index %
          AppColors.providerChartColors.length];

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final isLoading = provider.isLoadingProviderPrices;
    final prices = provider.providerPrices;
    final last24h = provider.providerLast24h;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryContainer(context);

    // Sorted list of providers that have data for the selected fuel type.
    final providers = prices == null
        ? <String>[]
        : (prices.keys
              .where((k) => prices[k]!.containsKey(_selectedFuelType))
              .toList()
            ..sort((a, b) => _providerName(a).compareTo(_providerName(b))));

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        top: AppSizes.space4,
        bottom: bottomPadding + AppSizes.space8 * 3,
      ),
      children: [
        _SectionHeader(context.l10n.statisticsKjederChartTitle),
        const SizedBox(height: AppSizes.space3),

        // Period toggle pills
        Row(
          children: [
            _ToggleBtn(
              label: context.l10n.statisticsLast24h,
              isActive: _show24h,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () => setState(() {
                _show24h = true;
                _hiddenProviders = {};
                _touchedSpots = null;
              }),
            ),
            const SizedBox(width: AppSizes.space2),
            _ToggleBtn(
              label: context.l10n.statisticsLast30d,
              isActive: !_show24h,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () => setState(() {
                _show24h = false;
                _hiddenProviders = {};
                _touchedSpots = null;
              }),
            ),
          ],
        ),

        // Fuel type filter pills (only for 30-day chart)
        if (!_show24h) ...[
          const SizedBox(height: AppSizes.space3),
          Row(
            children: FuelType.values.map((type) {
              final isActive = type == _selectedFuelType;
              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.space2),
                child: _ToggleBtn(
                  label: type.localizedName(context),
                  isActive: isActive,
                  activeColor: activeColor,
                  isDark: isDark,
                  onTap: () => setState(() {
                    _selectedFuelType = type;
                    _hiddenProviders = {};
                    _touchedSpots = null;
                  }),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: AppSizes.space4),

        // Chart or table card
        if (isLoading)
          _SkeletonPulse(
            child: _show24h ? _KjederTableSkeleton() : _KjederChartSkeleton(),
          )
        else if (_show24h)
          _Provider24hTable(last24h: last24h)
        else if (prices == null || providers.isEmpty)
          _ChartShell(
            child: SizedBox(
              height: 120,
              child: Center(
                child: Text('–', style: AppTextStyles.priceLarge(context)),
              ),
            ),
          )
        else
          _ChartShell(
            child: _ProviderLineChart(
              prices: prices,
              providers: providers,
              selectedFuelType: _selectedFuelType,
              hiddenProviders: _hiddenProviders,
              touchedSpots: _touchedSpots,
              colorForIndex: _colorForIndex,
              isDark: isDark,
              onTouch: (spots) => setState(() => _touchedSpots = spots),
              onTouchEnd: () => setState(() => _touchedSpots = null),
              onToggleProvider: (key) => setState(() {
                if (_hiddenProviders.contains(key)) {
                  _hiddenProviders.remove(key);
                } else if (_hiddenProviders.length < providers.length - 1) {
                  _hiddenProviders.add(key);
                }
              }),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 24h provider price table
// ---------------------------------------------------------------------------

enum _SortColumn { provider, petrol95, petrol98, diesel }

extension _SortColumnFuelType on _SortColumn {
  FuelType? get fuelType => switch (this) {
    _SortColumn.petrol95 => FuelType.petrol95,
    _SortColumn.petrol98 => FuelType.petrol98,
    _SortColumn.diesel => FuelType.diesel,
    _SortColumn.provider => null,
  };
}

class _Provider24hTable extends StatefulWidget {
  final Map<String, Map<FuelType, double>>? last24h;

  const _Provider24hTable({required this.last24h});

  @override
  State<_Provider24hTable> createState() => _Provider24hTableState();
}

class _Provider24hTableState extends State<_Provider24hTable> {
  _SortColumn _sortColumn = _SortColumn.petrol95;
  bool _sortAscending = true; // ascending = cheapest first

  @override
  Widget build(BuildContext context) {
    final last24h = widget.last24h;

    final entries = last24h == null
        ? <(String, Map<FuelType, double>)>[]
        : [
            for (final e in last24h.entries)
              if (e.value.isNotEmpty) (e.key, e.value),
          ];

    entries.sort((a, b) {
      int cmp;
      final fuelType = _sortColumn.fuelType;
      if (fuelType == null) {
        cmp = _providerName(a.$1).compareTo(_providerName(b.$1));
      } else {
        final priceA = a.$2[fuelType];
        final priceB = b.$2[fuelType];
        if (priceA == null && priceB == null) {
          cmp = 0;
        } else if (priceA == null) {
          cmp = 1;
        } else if (priceB == null) {
          cmp = -1;
        } else {
          cmp = priceA.compareTo(priceB);
        }
      }
      return _sortAscending ? cmp : -cmp;
    });

    const fuelColumns = [
      (_SortColumn.petrol95, FuelType.petrol95),
      (_SortColumn.petrol98, FuelType.petrol98),
      (_SortColumn.diesel, FuelType.diesel),
    ];

    const colWidth = 52.0;

    Widget columnHeader(String label, _SortColumn col) {
      final active = _sortColumn == col;
      return GestureDetector(
        onTap: () => setState(() {
          if (_sortColumn == col) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = col;
            _sortAscending = true;
          }
        }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.chipLabel(context).copyWith(
                color: active
                    ? AppColors.primaryContainer(context)
                    : AppColors.textMuted(context),
              ),
            ),
            if (active)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: AppColors.primaryContainer(context),
              ),
          ],
        ),
      );
    }

    String fuelLabel(FuelType ft) => switch (ft) {
      FuelType.petrol95 => '95',
      FuelType.petrol98 => '98',
      FuelType.diesel => 'D',
    };

    return _ChartShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space4),
        child: entries.isEmpty
            ? SizedBox(
                height: 120,
                child: Center(
                  child: Text('–', style: AppTextStyles.priceLarge(context)),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: columnHeader(
                          context.l10n.statisticsKjederBrandColumn,
                          _SortColumn.provider,
                        ),
                      ),
                      for (final (col, ft) in fuelColumns)
                        SizedBox(
                          width: colWidth,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: columnHeader(fuelLabel(ft), col),
                          ),
                        ),
                    ],
                  ),
                  Divider(thickness: 0.5, color: AppColors.border(context)),
                  // Data rows
                  for (int i = 0; i < entries.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.border(context),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.space2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _providerName(entries[i].$1),
                              style: AppTextStyles.label(context),
                            ),
                          ),
                          for (final (_, ft) in fuelColumns)
                            SizedBox(
                              width: colWidth,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  entries[i].$2[ft] != null
                                      ? entries[i].$2[ft]!.toStringAsFixed(2)
                                      : '–',
                                  style: AppTextStyles.label(context).copyWith(
                                    color: entries[i].$2[ft] != null
                                        ? null
                                        : AppColors.textMuted(context),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kjeder skeleton widgets
// ---------------------------------------------------------------------------

class _KjederTableSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const colWidth = 52.0;
    const boxW = 28.0;
    const gapW = colWidth - boxW;
    final providerWidths = [70.0, 55.0, 90.0, 62.0, 80.0, 48.0, 75.0];

    return _ChartShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const _SkeletonBox(
                  width: 40,
                  height: 11,
                  radius: AppSizes.radiusXs,
                ),
                const Spacer(),
                const _SkeletonBox(
                  width: 14,
                  height: 11,
                  radius: AppSizes.radiusXs,
                ),
                const SizedBox(width: gapW),
                const _SkeletonBox(
                  width: 14,
                  height: 11,
                  radius: AppSizes.radiusXs,
                ),
                const SizedBox(width: gapW),
                const _SkeletonBox(
                  width: 10,
                  height: 11,
                  radius: AppSizes.radiusXs,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space2),
            Divider(thickness: 0.5, color: AppColors.border(context)),
            for (int i = 0; i < providerWidths.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.border(context),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.space2),
                child: Row(
                  children: [
                    _SkeletonBox(
                      width: providerWidths[i],
                      height: 13,
                      radius: AppSizes.radiusXs,
                    ),
                    const Spacer(),
                    const _SkeletonBox(
                      width: boxW,
                      height: 13,
                      radius: AppSizes.radiusXs,
                    ),
                    const SizedBox(width: gapW),
                    const _SkeletonBox(
                      width: boxW,
                      height: 13,
                      radius: AppSizes.radiusXs,
                    ),
                    const SizedBox(width: gapW),
                    const _SkeletonBox(
                      width: boxW,
                      height: 13,
                      radius: AppSizes.radiusXs,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KjederChartSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final legendWidths = [50.0, 45.0, 60.0, 40.0, 55.0, 48.0];

    return _ChartShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Y-axis label column
                  SizedBox(
                    width: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < 5; i++)
                          const _SkeletonBox(
                            width: 36,
                            height: 10,
                            radius: AppSizes.radiusXs,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.space2),
                  // Chart area: horizontal guide lines
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < 5; i++)
                          const _SkeletonBox(height: 1, radius: 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space4),
            // Legend chips
            Wrap(
              spacing: AppSizes.space4,
              runSpacing: AppSizes.space2,
              children: [
                for (int i = 0; i < legendWidths.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SkeletonBox(width: 10, height: 10, radius: 5),
                      const SizedBox(width: AppSizes.space2),
                      _SkeletonBox(
                        width: legendWidths[i],
                        height: 12,
                        radius: AppSizes.radiusXs,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  final Widget child;
  const _ChartShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: child,
    );
  }
}

class _ProviderLineChart extends StatelessWidget {
  final Map<String, Map<FuelType, List<ProviderPriceDayPoint>>> prices;
  final List<String> providers;
  final FuelType selectedFuelType;
  final Set<String> hiddenProviders;
  final List<LineBarSpot>? touchedSpots;
  final Color Function(int index) colorForIndex;
  final bool isDark;
  final void Function(List<LineBarSpot>) onTouch;
  final VoidCallback onTouchEnd;
  final void Function(String key) onToggleProvider;

  const _ProviderLineChart({
    required this.prices,
    required this.providers,
    required this.selectedFuelType,
    required this.hiddenProviders,
    required this.touchedSpots,
    required this.colorForIndex,
    required this.isDark,
    required this.onTouch,
    required this.onTouchEnd,
    required this.onToggleProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Compute global date range and price bounds across all visible providers.
    DateTime? earliest;
    DateTime? latest;
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    final visibleProviders = providers
        .where((p) => !hiddenProviders.contains(p))
        .toList();

    for (final providerKey in visibleProviders) {
      final points = prices[providerKey]?[selectedFuelType] ?? [];
      for (final pt in points) {
        if (earliest == null || pt.date.isBefore(earliest)) earliest = pt.date;
        if (latest == null || pt.date.isAfter(latest)) latest = pt.date;
        minPrice = min(minPrice, pt.price);
        maxPrice = max(maxPrice, pt.price);
      }
    }

    if (earliest == null || latest == null) {
      return const SizedBox(height: 240);
    }

    final dateRange = latest.difference(earliest).inDays.toDouble();
    final xMin = dateRange == 0 ? -1.0 : 0.0;
    final xMax = dateRange == 0 ? 1.0 : dateRange;

    final rawYPad = (maxPrice - minPrice) * 0.12;
    final yPad = rawYPad == 0 ? maxPrice * 0.05 : rawYPad;
    final yMin = (minPrice - yPad).floorToDouble();
    final yMax = (maxPrice + yPad).ceilToDouble();

    final gridColor = AppColors.border(context).withValues(alpha: 0.3);
    final labelColor = AppColors.textMuted(context);
    final dateFormat = DateFormat('d/M');

    final barDataList = <LineChartBarData>[];
    for (int i = 0; i < providers.length; i++) {
      final key = providers[i];
      if (hiddenProviders.contains(key)) continue;
      final color = colorForIndex(i);
      var spots = (prices[key]?[selectedFuelType] ?? []).map((pt) {
        final x = pt.date.difference(earliest!).inDays.toDouble();
        return FlSpot(x, double.parse(pt.price.toStringAsFixed(2)));
      }).toList();
      if (spots.length == 1) {
        spots = [FlSpot(spots[0].x - 0.01, spots[0].y), spots[0]];
      }
      if (spots.isEmpty) continue;
      barDataList.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: color,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final isTouched =
                  touchedSpots?.any((s) => s.x == spot.x && s.y == spot.y) ??
                  false;
              return FlDotCirclePainter(
                radius: isTouched ? 5 : 2.5,
                color: color,
                strokeWidth: 1.5,
                strokeColor: isDark ? AppColors.darkBackground : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: true, color: color.withAlpha(18)),
        ),
      );
    }

    // Map bar index → provider key for tooltip lookup.
    final barProviderKeys = providers
        .where((p) => !hiddenProviders.contains(p))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: xMin,
                    maxX: xMax,
                    minY: yMin,
                    maxY: yMax,
                    gridData: FlGridData(
                      horizontalInterval: ((yMax - yMin) / 4)
                          .ceilToDouble()
                          .clamp(0.5, 10),
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: gridColor, strokeWidth: 0.5),
                      getDrawingVerticalLine: (_) =>
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
                                style: TextStyle(
                                  fontSize: AppSizes.fontXs,
                                  color: labelColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, _) => Text(
                            value.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchCallback: (event, response) {
                        if (response?.lineBarSpots != null &&
                            response!.lineBarSpots!.isNotEmpty) {
                          onTouch(response.lineBarSpots!);
                        } else if (event is FlLongPressEnd ||
                            event is FlPanEndEvent ||
                            event is FlTapUpEvent) {
                          onTouchEnd();
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => Colors.transparent,
                        getTooltipItems: (spots) =>
                            spots.map((_) => null).toList(),
                      ),
                    ),
                    lineBarsData: barDataList,
                  ),
                ),
                // Custom tooltip overlay
                if (touchedSpots != null && touchedSpots!.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 52,
                    child: _ChartTooltip(
                      spots: touchedSpots!,
                      earliest: earliest,
                      dateFormat: dateFormat,
                      isDark: isDark,
                      barProviderKeys: barProviderKeys,
                      colorForIndex: (idx) => colorForIndex(
                        providers.indexOf(barProviderKeys[idx]),
                      ),
                      context: context,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space4),
          // Legend
          Wrap(
            spacing: AppSizes.space4,
            runSpacing: AppSizes.space2,
            children: [
              for (int i = 0; i < providers.length; i++)
                _LegendChip(
                  label: _providerName(providers[i]),
                  color: colorForIndex(i),
                  isVisible: !hiddenProviders.contains(providers[i]),
                  onTap: () => onToggleProvider(providers[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartTooltip extends StatelessWidget {
  final List<LineBarSpot> spots;
  final DateTime? earliest;
  final DateFormat dateFormat;
  final bool isDark;
  final List<String> barProviderKeys;
  final Color Function(int barIndex) colorForIndex;
  final BuildContext context;

  const _ChartTooltip({
    required this.spots,
    required this.earliest,
    required this.dateFormat,
    required this.isDark,
    required this.barProviderKeys,
    required this.colorForIndex,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    if (earliest == null) return const SizedBox.shrink();
    final date = earliest!.add(Duration(days: spots.first.x.toInt()));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space3,
        vertical: AppSizes.space2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceHighest : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.border(ctx), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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
              ctx,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.space1),
          for (final spot in spots)
            if (spot.barIndex < barProviderKeys.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorForIndex(spot.barIndex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.space2),
                    Text(
                      '${_providerName(barProviderKeys[spot.barIndex])}: '
                      '${spot.y.toStringAsFixed(2)} ${context.l10n.krSuffix}',
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: colorForIndex(spot.barIndex),
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

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isVisible;
  final VoidCallback onTap;

  const _LegendChip({
    required this.label,
    required this.color,
    required this.isVisible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isVisible ? color : color.withAlpha(55),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.space1),
          Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: isVisible
                  ? AppColors.textPrimary(context)
                  : AppColors.textMuted(context),
              decoration: isVisible ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rapporter tab
// ---------------------------------------------------------------------------

class _RapporterTab extends StatefulWidget {
  final StatisticsProvider provider;
  final VoidCallback onRefresh;

  const _RapporterTab({required this.provider, required this.onRefresh});

  @override
  State<_RapporterTab> createState() => _RapporterTabState();
}

class _RapporterTabState extends State<_RapporterTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.provider.fetchContributors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final listPadding = EdgeInsets.only(
      left: AppSizes.screenPadding,
      right: AppSizes.screenPadding,
      top: AppSizes.space4,
      bottom: bottomPadding + AppSizes.space8 * 3,
    );

    if (provider.error != null && provider.statistics == null) {
      return Padding(
        padding: listPadding,
        child: Text(
          provider.error!,
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
      );
    }

    final isLoading = provider.isLoading || provider.isRefreshing;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: listPadding,
      children: [
        _SectionHeader(context.l10n.statisticsActivity),
        const SizedBox(height: AppSizes.space3),
        _ActivityCard(
          activity: provider.statistics?.activity,
          isLoading: isLoading,
        ),
        const SizedBox(height: AppSizes.space6),
        _SectionHeader(context.l10n.statisticsTopContributors),
        const SizedBox(height: AppSizes.space3),
        _ContributorsCard(
          contributors: provider.contributors,
          isLoading: isLoading || provider.isLoadingContributors,
          error: provider.contributorsError,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Contributors card
// ---------------------------------------------------------------------------

class _ContributorsCard extends StatefulWidget {
  final ContributorStats? contributors;
  final bool isLoading;
  final String? error;

  const _ContributorsCard({
    required this.contributors,
    required this.isLoading,
    this.error,
  });

  @override
  State<_ContributorsCard> createState() => _ContributorsCardState();
}

class _ContributorsCardState extends State<_ContributorsCard> {
  bool _showTotal = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryContainer(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final list = _showTotal
        ? (widget.contributors?.total ?? [])
        : (widget.contributors?.last24Hours ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ToggleBtn(
              label: context.l10n.statisticsLast24h,
              isActive: !_showTotal,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () => setState(() => _showTotal = false),
            ),
            const SizedBox(width: AppSizes.space2),
            _ToggleBtn(
              label: context.l10n.statisticsContributorsAllTime,
              isActive: _showTotal,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () => setState(() => _showTotal = true),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space3),
        if (widget.isLoading)
          _buildSkeletonCard(context)
        else if (widget.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.space2),
            child: Text(widget.error!, style: AppTextStyles.meta(context)),
          )
        else if (widget.contributors == null)
          const SizedBox.shrink()
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.space2),
            child: Text('—', style: AppTextStyles.meta(context)),
          )
        else
          _buildListCard(context, list),
      ],
    );
  }

  Widget _buildListCard(BuildContext context, List<Contributor> list) {
    final top3 = list.take(3).toList();
    final rest = list.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top3.isNotEmpty) _Top3PodiumCard(entries: top3),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSizes.space3),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.border(context), width: 0.5),
            ),
            child: Column(
              children: [
                for (int i = 0; i < rest.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: AppColors.border(context),
                    ),
                  _ContributorRow(rank: i + 4, contributor: rest[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < 5; i++) ...[
            if (i > 0)
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppColors.border(context),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space4,
                vertical: AppSizes.space3,
              ),
              child: Row(
                children: const [
                  _SkeletonBox(
                    width: 20,
                    height: 14,
                    radius: AppSizes.radiusXs,
                  ),
                  SizedBox(width: AppSizes.space3),
                  _SkeletonBox(
                    width: 120,
                    height: 14,
                    radius: AppSizes.radiusXs,
                  ),
                  Spacer(),
                  _SkeletonBox(
                    width: 32,
                    height: 14,
                    radius: AppSizes.radiusXs,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    return _SkeletonPulse(child: card);
  }
}

class _ContributorRow extends StatelessWidget {
  final int rank;
  final Contributor contributor;

  const _ContributorRow({required this.rank, required this.contributor});

  @override
  Widget build(BuildContext context) {
    final name = contributor.displayName ?? context.l10n.statisticsAnonymous;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space4,
        vertical: AppSizes.space3,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.space6,
            child: Text('#$rank', style: AppTextStyles.meta(context)),
          ),
          const SizedBox(width: AppSizes.space3),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            contributor.count.toString(),
            style: AppTextStyles.priceMedium(context),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top-3 podium card
// ---------------------------------------------------------------------------

class _Top3PodiumCard extends StatelessWidget {
  final List<Contributor> entries;

  const _Top3PodiumCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.rankColor(context, 1);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.40 : 0.55),
          width: 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: gold.withValues(alpha: 0.07),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space4,
              vertical: AppSizes.space3,
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, size: 15, color: gold),
                const SizedBox(width: AppSizes.space2),
                Text(
                  'TOP 3',
                  style: AppTextStyles.sectionHeader(
                    context,
                  ).copyWith(color: gold, letterSpacing: 2.0),
                ),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: gold.withValues(alpha: 0.20),
          ),
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppColors.border(context),
              ),
            _PodiumRow(rank: i + 1, contributor: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final int rank;
  final Contributor contributor;

  const _PodiumRow({required this.rank, required this.contributor});

  @override
  Widget build(BuildContext context) {
    final name = contributor.displayName ?? context.l10n.statisticsAnonymous;
    final medal = AppColors.rankColor(context, rank);
    final isFirst = rank == 1;
    final badgeSize = isFirst ? 30.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.space4,
        vertical: isFirst ? AppSizes.space4 : AppSizes.space3,
      ),
      child: Row(
        children: [
          // Medal badge
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medal.withValues(alpha: 0.15),
              border: Border.all(
                color: medal.withValues(alpha: 0.55),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTextStyles.labelBold(context).copyWith(
                  color: medal,
                  fontSize: isFirst ? AppSizes.fontMd : AppSizes.fontSm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.space3),
          Expanded(
            child: Text(
              name,
              style: isFirst
                  ? AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(fontSize: AppSizes.fontLg)
                  : AppTextStyles.bodyMedium(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            contributor.count.toString(),
            style:
                (isFirst
                        ? AppTextStyles.priceLarge(context)
                        : AppTextStyles.priceMedium(context))
                    .copyWith(color: medal),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.heading(context));
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space4,
          vertical: AppSizes.space2,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isActive ? activeColor : AppColors.border(context),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.chipLabel(context).copyWith(
            color: isActive
                ? (isDark ? AppColors.darkBackground : Colors.white)
                : AppColors.textMuted(context),
          ),
        ),
      ),
    );
  }
}

class _ExtremesCard extends StatelessWidget {
  final Map<FuelType, PriceExtremes> extremes;
  final bool isLoading;
  const _ExtremesCard({required this.extremes, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final fuelTypes = FuelType.values;
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        children: [
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space4,
              vertical: AppSizes.space3,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Siste 24 timer',
                    style: AppTextStyles.label(context),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.statisticsLowest,
                    style: AppTextStyles.labelBold(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSizes.space2),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.statisticsHighest,
                    style: AppTextStyles.labelBold(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.border(context)),
          // Fuel type rows
          for (int i = 0; i < fuelTypes.length; i++) ...[
            if (i > 0)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: AppSizes.space4),
                color: AppColors.border(context),
              ),
            _ExtremesRow(
              fuelType: fuelTypes[i],
              extremes: extremes[fuelTypes[i]],
              isLoading: isLoading,
            ),
          ],
        ],
      ),
    );
    return isLoading ? _SkeletonPulse(child: card) : card;
  }
}

class _ExtremesRow extends StatelessWidget {
  final FuelType fuelType;
  final PriceExtremes? extremes;
  final bool isLoading;
  const _ExtremesRow({
    required this.fuelType,
    required this.extremes,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final greenColor = AppColors.secondary(context);

    final stationProvider = context.read<StationProvider>();
    final lowestStation = extremes?.lowestStationId != null
        ? stationProvider.getStation(extremes!.lowestStationId!)
        : null;
    final highestStation = extremes?.highestStationId != null
        ? stationProvider.getStation(extremes!.highestStationId!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space4,
        vertical: AppSizes.space3,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              fuelType.localizedName(context),
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
          Expanded(
            flex: 2,
            child: _PriceBox(
              price: extremes?.lowestPrice,
              stationName: extremes?.lowestStationName,
              priceColor: greenColor,
              isLoading: isLoading,
              onTap: lowestStation != null
                  ? () => Navigator.pushNamed(
                      context,
                      AppRoutes.stationDetail,
                      arguments: lowestStation,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSizes.space2),
          Expanded(
            flex: 2,
            child: _PriceBox(
              price: extremes?.highestPrice,
              stationName: extremes?.highestStationName,
              priceColor: errorColor,
              isLoading: isLoading,
              onTap: highestStation != null
                  ? () => Navigator.pushNamed(
                      context,
                      AppRoutes.stationDetail,
                      arguments: highestStation,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final double? price;
  final String? stationName;
  final Color priceColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PriceBox({
    required this.price,
    required this.stationName,
    required this.priceColor,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (!isLoading && price != null) ? onTap : null,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Container(
          width: double.infinity,
          height: 68,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space3,
            vertical: AppSizes.space1,
          ),
          decoration: BoxDecoration(
            color: priceColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(
              color: priceColor.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                _SkeletonBox(height: 20, width: 52, radius: AppSizes.radiusXs),
                const SizedBox(height: AppSizes.space1),
                _SkeletonBox(height: 28, width: 64, radius: AppSizes.radiusXs),
              ] else if (price != null) ...[
                Text(
                  '${price!.toStringAsFixed(2)} kr',
                  style: AppTextStyles.priceMedium(
                    context,
                  ).copyWith(color: priceColor),
                  textAlign: TextAlign.center,
                ),
                if (stationName != null) ...[
                  const SizedBox(height: AppSizes.space1),
                  Text(
                    stationName!,
                    style: AppTextStyles.label(context).copyWith(height: 1.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else
                Text(
                  '–',
                  style: AppTextStyles.priceMedium(context),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoLocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space4),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: AppSizes.fontLg,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(width: AppSizes.space3),
          Expanded(
            child: Text(
              context.l10n.statisticsNoLocation,
              style: AppTextStyles.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityStats? activity;
  final bool isLoading;
  const _ActivityCard({required this.activity, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ActivityTile(
                count: activity?.last24Hours,
                label: context.l10n.statisticsLast24h,
                isLoading: isLoading,
              ),
            ),
            VerticalDivider(width: 0.5, color: AppColors.border(context)),
            Expanded(
              child: _ActivityTile(
                count: activity?.last7Days,
                label: context.l10n.statisticsLast7d,
                isLoading: isLoading,
              ),
            ),
            VerticalDivider(width: 0.5, color: AppColors.border(context)),
            Expanded(
              child: _ActivityTile(
                count: activity?.last30Days,
                label: context.l10n.statisticsLast30d,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
    return isLoading ? _SkeletonPulse(child: card) : card;
  }
}

class _ActivityTile extends StatelessWidget {
  final int? count;
  final String label;
  final bool isLoading;
  const _ActivityTile({
    required this.count,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.space4,
        horizontal: AppSizes.space3,
      ),
      child: Column(
        children: [
          if (isLoading)
            const _SkeletonBox(width: 40, height: 28, radius: AppSizes.radiusXs)
          else
            Text(
              (count ?? 0).toString(),
              style: AppTextStyles.priceLarge(context),
            ),
          const SizedBox(height: AppSizes.space1),
          Text(
            label,
            style: AppTextStyles.meta(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loaders
// ---------------------------------------------------------------------------

class _SkeletonPulse extends StatefulWidget {
  final Widget child;
  const _SkeletonPulse({required this.child});

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.35,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBox({
    this.width,
    required this.height,
    this.radius = AppSizes.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
