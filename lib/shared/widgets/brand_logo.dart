import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 74,
    this.center = true,
  });

  final double height;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final Widget logo = Image.asset(
      'assets/branding/nandx_wordmark.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        'NANDX',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );

    if (center) {
      return Center(child: logo);
    }

    return logo;
  }
}
