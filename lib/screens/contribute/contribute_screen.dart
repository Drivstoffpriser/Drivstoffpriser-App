import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/fuel_type.dart';
import '../../models/station.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../services/distance_service.dart';
import '../../widgets/brand_logo.dart';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  int _currentStep = 0;
  Station? _selectedStation;
  FuelType? _selectedFuelType;

  void _selectStation(Station station) {
    setState(() {
      _selectedStation = station;
      _currentStep = 1;
    });
  }

  void _selectFuelType(FuelType type) {
    setState(() {
      _selectedFuelType = type;
      _currentStep = 2;
    });
  }

  void _goToStep(int step) {
    if (step <= _currentStep) {
      setState(() => _currentStep = step);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background(context),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                context.l10n.contributeData,
                style: AppTextStyles.sectionHeader(
                  context,
                ).copyWith(fontSize: 14, color: AppColors.textPrimary(context)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  _StepIndicator(
                    currentStep: _currentStep,
                    onStepTap: _goToStep,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Step content
          if (_currentStep == 0)
            _StationSelectionStep(onStationSelected: _selectStation)
          else if (_currentStep == 1)
            SliverToBoxAdapter(
              child: _FuelTypeStep(
                station: _selectedStation!,
                onFuelTypeSelected: _selectFuelType,
              ),
            )
          else if (_currentStep == 2)
            SliverToBoxAdapter(
              child: _PriceEntryStep(
                station: _selectedStation!,
                fuelType: _selectedFuelType!,
              ),
            ),

          // Bottom spacing for nav
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 120,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTap;

  const _StepIndicator({required this.currentStep, required this.onStepTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryContainer(context);
    final labels = [
      context.l10n.station,
      context.l10n.fuelType,
      context.l10n.price,
    ];

    return Row(
      children: List.generate(3, (i) {
        final isActive = i == currentStep;
        final isComplete = i < currentStep;

        return Expanded(
          child: GestureDetector(
            onTap: isComplete ? () => onStepTap(i) : null,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive || isComplete
                        ? activeColor
                        : AppColors.surfaceLow(context),
                    border: Border.all(
                      color: isActive || isComplete
                          ? activeColor
                          : AppColors.border(context),
                    ),
                  ),
                  child: Center(
                    child: isComplete
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: isDark
                                ? AppColors.darkBackground
                                : Colors.white,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? (isDark
                                        ? AppColors.darkBackground
                                        : Colors.white)
                                  : AppColors.textMuted(context),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels[i],
                    style: AppTextStyles.label(context).copyWith(
                      color: isActive || isComplete
                          ? AppColors.textPrimary(context)
                          : AppColors.textMuted(context),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StationSelectionStep extends StatelessWidget {
  final ValueChanged<Station> onStationSelected;

  const _StationSelectionStep({required this.onStationSelected});

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final sorted = stationProvider.sortedStations(
      userLat: locationProvider.position?.latitude,
      userLng: locationProvider.position?.longitude,
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(context.l10n.selectStation, style: AppTextStyles.title(context)),
          const SizedBox(height: 4),
          Text(
            context.l10n.chooseStationSubtitle,
            style: AppTextStyles.meta(context),
          ),
          const SizedBox(height: 16),
          ...sorted.take(20).map((station) {
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

            return _StationSelectionCard(
              station: station,
              distanceStr: distanceStr,
              onTap: () => onStationSelected(station),
            );
          }),
        ]),
      ),
    );
  }
}

class _StationSelectionCard extends StatefulWidget {
  final Station station;
  final String? distanceStr;
  final VoidCallback onTap;

  const _StationSelectionCard({
    required this.station,
    this.distanceStr,
    required this.onTap,
  });

  @override
  State<_StationSelectionCard> createState() => _StationSelectionCardState();
}

class _StationSelectionCardState extends State<_StationSelectionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context), width: 0.5),
            ),
            child: Row(
              children: [
                BrandLogo(brand: widget.station.brand, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: AppTextStyles.bodyMedium(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        [
                          if (widget.station.city.isNotEmpty)
                            widget.station.city,
                          if (widget.distanceStr != null) widget.distanceStr!,
                        ].join(' · '),
                        style: AppTextStyles.meta(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textMuted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FuelTypeStep extends StatelessWidget {
  final Station station;
  final ValueChanged<FuelType> onFuelTypeSelected;

  const _FuelTypeStep({
    required this.station,
    required this.onFuelTypeSelected,
  });

  static const _fuelIcons = {
    FuelType.petrol95: Icons.local_gas_station,
    FuelType.petrol98: Icons.local_gas_station,
    FuelType.diesel: Icons.oil_barrel,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected station summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                BrandLogo(brand: station.brand, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    station.name,
                    style: AppTextStyles.bodyMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.primaryContainer(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.selectFuelGrade,
            style: AppTextStyles.title(context),
          ),
          const SizedBox(height: 4),
          Text(context.l10n.whatFuelType, style: AppTextStyles.meta(context)),
          const SizedBox(height: 16),
          // 2-column grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: FuelType.values.map((type) {
              return _FuelTypeCard(
                type: type,
                icon: _fuelIcons[type] ?? Icons.local_gas_station,
                onTap: () => onFuelTypeSelected(type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FuelTypeCard extends StatefulWidget {
  final FuelType type;
  final IconData icon;
  final VoidCallback onTap;

  const _FuelTypeCard({
    required this.type,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_FuelTypeCard> createState() => _FuelTypeCardState();
}

class _FuelTypeCardState extends State<_FuelTypeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryContainer(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 28, color: activeColor),
              const SizedBox(height: 8),
              Text(
                widget.type.localizedName(context),
                style: AppTextStyles.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceEntryStep extends StatefulWidget {
  final Station station;
  final FuelType fuelType;

  const _PriceEntryStep({required this.station, required this.fuelType});

  @override
  State<_PriceEntryStep> createState() => _PriceEntryStepState();
}

class _PriceEntryStepState extends State<_PriceEntryStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final price = double.tryParse(text);
    if (price == null) return;

    // Navigate to the existing submit price screen with the station
    Navigator.pushNamed(
      context,
      AppRoutes.submitPrice,
      arguments: widget.station,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryContainer(context);
    final stationProvider = context.watch<StationProvider>();
    final currentPrice = stationProvider.getPriceForStation(widget.station.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station + fuel type summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                BrandLogo(brand: widget.station.brand, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: AppTextStyles.bodyMedium(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.fuelType.localizedName(context),
                        style: AppTextStyles.meta(context),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, size: 18, color: activeColor),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(context.l10n.enterPrice, style: AppTextStyles.title(context)),
          const SizedBox(height: 16),

          // Current average pill
          if (currentPrice != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: activeColor),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.currentAvg(
                      '${currentPrice.price.toStringAsFixed(2)} ${context.l10n.nok}/${widget.fuelType.unit}',
                    ),
                    style: AppTextStyles.label(
                      context,
                    ).copyWith(color: activeColor),
                  ),
                ],
              ),
            ),

          // Large price input
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context), width: 0.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTextStyles.priceLarge(
                          context,
                        ).copyWith(fontSize: 36),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: AppTextStyles.priceLarge(context).copyWith(
                            fontSize: 36,
                            color: AppColors.textMuted(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.nok,
                      style: AppTextStyles.title(
                        context,
                      ).copyWith(color: AppColors.textMuted(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(context.l10n.perL, style: AppTextStyles.meta(context)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit button — gradient cyan
          _GradientButton(
            label: context.l10n.verifyAndSubmit,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({required this.label, required this.onPressed});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
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
          width: double.infinity,
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
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isDark ? AppColors.darkBackground : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
