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

  const BrandLogo({super.key, required this.brand, this.radius = 20});

  static const _brandAssets = {
    'Circle K': 'assets/logos/circle-k.png',
    'Shell': 'assets/logos/shell.png',
    'Esso': 'assets/logos/esso.png',
    'YX': 'assets/logos/yx.png',
    'Uno-X': 'assets/logos/uno-x.png',
    'St1': 'assets/logos/st1.png',
    'YX Truck': 'assets/logos/yx-truck.png',
    'Tanken': 'assets/logos/tanken.png',
  };

  @override
  Widget build(BuildContext context) {
    final path = _brandAssets[brand];

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: path != null
          ? ClipOval(
              child: Image.asset(
                path,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackInitial(context),
              ),
            )
          : _fallbackInitial(context),
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
