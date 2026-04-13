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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../l10n/l10n_helper.dart';
import '../../../models/station.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/station_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/distance_service.dart';

/// Distance threshold in meters to show the "nearby station" banner.
const _nearbyThresholdMeters = 500.0;

class NearbyStationBanner extends StatefulWidget {
  const NearbyStationBanner({super.key});

  @override
  State<NearbyStationBanner> createState() => _NearbyStationBannerState();
}

class _NearbyStationBannerState extends State<NearbyStationBanner> {
  String? _dismissedStationId;

  Station? _findNearestStation() {
    final locationProvider = context.watch<LocationProvider>();
    final stationProvider = context.watch<StationProvider>();

    if (!locationProvider.hasLocation) return null;
    final pos = locationProvider.position!;

    Station? nearest;
    double nearestDist = double.infinity;

    for (final station in stationProvider.stations) {
      final dist = DistanceService.distanceInMeters(
        pos.latitude,
        pos.longitude,
        station.latitude,
        station.longitude,
      );
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = station;
      }
    }

    if (nearest == null || nearestDist > _nearbyThresholdMeters) return null;
    if (nearest.id == _dismissedStationId) return null;

    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final station = _findNearestStation();
    if (station == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withAlpha(220)
                : Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context).withAlpha(80)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsing dot.
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF00d2ff)
                      : const Color(0xFF0056b3),
                ),
              ),
              const SizedBox(width: 10),
              // Text.
              Expanded(
                child: Text(
                  context.l10n.nearbyStationPrompt(station.name),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withAlpha(220)
                        : Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Accept button.
              _BannerAction(
                icon: Icons.check_circle,
                color: const Color(0xFF4CAF50),
                onTap: () async {
                  final userProvider = context.read<UserProvider>();
                  if (!userProvider.isAuthenticated) {
                    await Navigator.pushNamed(context, AppRoutes.auth);
                    if (!context.mounted || !userProvider.isAuthenticated) {
                      return;
                    }
                  }
                  Navigator.pushNamed(
                    context,
                    AppRoutes.submitPrice,
                    arguments: station,
                  );
                },
              ),
              const SizedBox(width: 8),
              // Dismiss button.
              _BannerAction(
                icon: Icons.cancel,
                color: isDark
                    ? const Color(0xFFFF716C)
                    : const Color(0xFFE53935),
                onTap: () {
                  setState(() => _dismissedStationId = station.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BannerAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withAlpha(30),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
