import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final String brand;
  final double radius;

  const BrandLogo({
    super.key,
    required this.brand,
    this.radius = 20,
  });

  static const _brandAssets = {
    'Circle K': 'assets/logos/circle-k.png',
    'Shell': 'assets/logos/shell.png',
    'Esso': 'assets/logos/esso.png',
    'YX': 'assets/logos/yx.png',
    'Uno-X': 'assets/logos/uno-x.png',
  };

  @override
  Widget build(BuildContext context) {
    final path = _brandAssets[brand];

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
    return Text(
      brand.isNotEmpty ? brand.substring(0, 1) : '?',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
