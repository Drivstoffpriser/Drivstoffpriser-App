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

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class BrandLogo extends StatelessWidget {
  final String brand;
  final double radius;

  /// Optional override URL — used for previewing proposed logos in admin screens.
  final String? logoUrl;

  const BrandLogo({
    super.key,
    required this.brand,
    this.radius = 20,
    this.logoUrl,
  });

  static const _brandAssets = {
    'Circle K': 'assets/logos/circle-k.png',
    'Shell': 'assets/logos/shell.png',
    'Esso': 'assets/logos/esso.png',
    'YX': 'assets/logos/yx.png',
    'Uno-X': 'assets/logos/uno-x.png',
    'St1': 'assets/logos/st1.png',
    'YX Truck': 'assets/logos/yx-truck.png',
    'Tanken': 'assets/logos/tanken.png',
    'Bunker Oil': 'assets/logos/bunker.png',
  };

  /// Remote brand logos loaded from Firestore (brand_logos aggregate).
  /// Populated by StationProvider on app startup.
  static final Map<String, String> _remoteLogos = {};

  /// Update the remote logos cache. Called by StationProvider after loading.
  static void setRemoteLogos(Map<String, String> logos) {
    _remoteLogos
      ..clear()
      ..addAll(logos);
  }

  /// Look up a remote logo URL for a brand. Used by StationMarker.
  static String? remoteLogoUrl(String brand) => _remoteLogos[brand];

  @override
  Widget build(BuildContext context) {
    final url = logoUrl ?? _remoteLogos[brand];
    final path = _brandAssets[brand];
    final size = radius * 2;

    Widget child;
    if (url != null) {
      child = ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => path != null
              ? _assetImage(path, size, context)
              : _fallbackInitial(context),
        ),
      );
    } else if (path != null) {
      child = _assetImage(path, size, context);
    } else {
      child = _fallbackInitial(context);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: child,
    );
  }

  Widget _assetImage(String path, double size, BuildContext context) {
    return ClipOval(
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackInitial(context),
      ),
    );
  }

  Widget _fallbackInitial(BuildContext context) {
    return Center(
      child: Text(
        brand.isNotEmpty ? brand.substring(0, 1).toUpperCase() : '?',
        style: AppTextStyles.bodyMedium(
          context,
        ).copyWith(fontSize: radius * 0.8, color: AppColors.textMuted(context)),
      ),
    );
  }
}
