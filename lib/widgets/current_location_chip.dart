import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../theme/app_colors.dart';

/// Location chip for Home — shows Geolocator city/country when available.
class CurrentLocationChip extends StatelessWidget {
  final bool loading;
  final LocationResolveState state;
  final UserLocation? location;
  final VoidCallback? onTap;

  const CurrentLocationChip({
    super.key,
    required this.loading,
    required this.state,
    this.location,
    this.onTap,
  });

  static const double _height = 34;

  String _statusText() {
    if (loading) return 'Detecting location...';

    switch (state) {
      case LocationResolveState.pending:
        return 'Tap to allow location';
      case LocationResolveState.success:
        if (location != null && location!.formatted.isNotEmpty) {
          return location!.formatted;
        }
        return 'Location detected';
      case LocationResolveState.denied:
        return 'Tap to allow location';
      case LocationResolveState.deniedForever:
        return 'Enable location in settings';
      case LocationResolveState.serviceDisabled:
        return 'Turn on location';
      case LocationResolveState.geocodeFailed:
        if (location != null && location!.country.isNotEmpty) {
          return location!.country;
        }
        if (location != null && location!.marketRegion.isNotEmpty) {
          return location!.marketRegion;
        }
        return 'Location unavailable';
      case LocationResolveState.unavailable:
        return 'Tap to retry location';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _statusText();
    final isSuccess = !loading &&
        (state == LocationResolveState.success ||
            state == LocationResolveState.geocodeFailed) &&
        location != null &&
        location!.formatted.isNotEmpty;

    final chip = Container(
      constraints: const BoxConstraints(minHeight: _height),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 15,
            color: loading ? kTextMuted : kAccent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: loading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: kAccent.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: TextStyle(
                          color: kTextSec.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isSuccess
                          ? kTextMain
                          : kTextMuted.withValues(alpha: 0.95),
                      fontSize: isSuccess ? 12 : 11,
                      fontWeight:
                          isSuccess ? FontWeight.w600 : FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
    );
  }
}
