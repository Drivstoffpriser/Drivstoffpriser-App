import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/station_provider.dart';

/// A small FAB-like button that opens a brand filter bottom sheet.
class BrandFilterButton extends StatelessWidget {
  final String heroTag;

  const BrandFilterButton({super.key, this.heroTag = 'brandFilter'});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final hasFilter = provider.selectedBrands.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.small(
          heroTag: heroTag,
          onPressed: () => _showBrandFilterSheet(context),
          child: ImageIcon(
            const AssetImage('assets/button/filtering.png'),
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        // Active filter indicator dot
        if (hasFilter)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showBrandFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _BrandFilterSheet(),
    );
  }
}

class _BrandFilterSheet extends StatelessWidget {
  const _BrandFilterSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final brands = provider.availableBrands;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter by Brand',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (provider.selectedBrands.isNotEmpty)
                TextButton(
                  onPressed: () => provider.clearBrandFilter(),
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: brands.map((brand) {
              final selected = provider.selectedBrands.contains(brand);
              return FilterChip(
                label: Text(brand),
                selected: selected,
                onSelected: (_) => provider.toggleBrand(brand),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
