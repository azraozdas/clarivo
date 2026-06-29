import 'package:flutter/material.dart';

/// Path to the main Clarivo logo asset used across the app.
const String kClarivoLogoAsset = 'assets/images/logos/Main_logo.png';

/// Reusable Clarivo logo — loads [Main_logo.png] from assets.
/// Use this widget anywhere the Clarivo brand mark appears.
class ClarivoLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const ClarivoLogo({
    super.key,
    this.size = 56,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kClarivoLogoAsset,
      width: size,
      height: size,
      fit: fit,
    );
  }
}
