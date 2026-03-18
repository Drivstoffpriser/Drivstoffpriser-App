import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final String brand;
  final double? size;
  final double radius;

  const BrandLogo({
    super.key,
    required this.brand,
    this.size,
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
    final effectiveRadius = size != null ? size! / 2 : radius;

    return CircleAvatar(
      radius: effectiveRadius,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        child: ClipOval(
          child: path != null
              ? Image.asset(
                  path,
                  width: effectiveRadius * 2,
                  height: effectiveRadius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallbackInitial(context, effectiveRadius),
                )
              : _fallbackInitial(context, effectiveRadius),
        ),
      ),
    );
  }

  Widget _fallbackInitial(BuildContext context, double r) {
    return Container(
      width: r * 2,
      height: r * 2,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        brand.isNotEmpty ? brand.substring(0, 1) : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: r * 0.8,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
