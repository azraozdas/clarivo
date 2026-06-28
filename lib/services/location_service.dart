import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// How the coordinates were obtained — never treat stale/mock as confirmed GPS.
enum LocationSource {
  freshGps,
  mockGps,
  staleCachedGps,
  unavailable,
}

/// Resolved place + broad market region from device GPS.
class UserLocation {
  final String city;
  final String country;
  final String marketRegion;
  final LocationSource source;
  final DateTime? positionTime;

  const UserLocation({
    this.city = '',
    this.country = '',
    this.marketRegion = 'Global',
    this.source = LocationSource.unavailable,
    this.positionTime,
  });

  bool get isConfirmedDeviceLocation =>
      source == LocationSource.freshGps ||
      source == LocationSource.staleCachedGps;

  String get formatted {
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }
}

enum LocationResolveState {
  pending,
  success,
  denied,
  deniedForever,
  serviceDisabled,
  geocodeFailed,
  unavailable,
}

class LocationResolveResult {
  final LocationResolveState state;
  final UserLocation? location;
  final LocationSource source;

  const LocationResolveResult({
    required this.state,
    this.location,
    this.source = LocationSource.unavailable,
  });
}

class LocationService {
  static const Duration _positionTimeout = Duration(seconds: 18);
  static const Duration _geocodeTimeout = Duration(seconds: 6);
  static const Duration _fetchTimeout = Duration(seconds: 22);

  static bool isPermissionGranted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

  static bool isPermissionDenied(LocationPermission permission) =>
      permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine;

  static bool isKnownEmulatorDefault(double lat, double lon) {
    return (lat - 37.4219983).abs() < 0.02 && (lon - (-122.084)).abs() < 0.02;
  }

  static String _coordinatesToRegion(double lat, double lon) {
    if (lat >= 35 && lat <= 71 && lon >= -10 && lon <= 40) return 'Europe';
    if (lat >= 15 && lat <= 72 && lon >= -170 && lon <= -50) {
      return 'North America';
    }
    if (lat >= -10 && lat <= 70 && lon >= 60 && lon <= 180) {
      return 'Asia-Pacific';
    }
    if (lat >= -60 && lat <= 15 && lon >= -90 && lon <= -30) {
      return 'South America';
    }
    return 'Global';
  }

  /// Fallback when platform geocoder returns nothing — country only from coords.
  static String _approxCountryFromCoordinates(double lat, double lon) {
    if (lat >= 47.2 && lat <= 55.1 && lon >= 5.8 && lon <= 15.1) {
      return 'Germany';
    }
    if (lat >= 41.0 && lat <= 52.5 && lon >= -5.5 && lon <= 9.5) {
      return 'France';
    }
    if (lat >= 50.0 && lat <= 59.0 && lon >= -8.5 && lon <= 2.0) {
      return 'United Kingdom';
    }
    if (lat >= 24.5 && lat <= 49.5 && lon >= -125.0 && lon <= -66.0) {
      return 'United States';
    }
    return '';
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static LocationSource _classifyPosition(Position position) {
    if (isKnownEmulatorDefault(position.latitude, position.longitude)) {
      return LocationSource.mockGps;
    }
    if (position.isMocked) {
      return LocationSource.mockGps;
    }
    final age = DateTime.now().difference(position.timestamp);
    if (age > const Duration(hours: 2)) {
      return LocationSource.staleCachedGps;
    }
    return LocationSource.freshGps;
  }

  static Future<({String city, String country})?> _reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(_geocodeTimeout, onTimeout: () => <Placemark>[]);

      if (placemarks.isEmpty) return null;

      for (final place in placemarks) {
        final city = _firstNonEmpty([
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.subLocality,
          place.name,
        ]);
        final country = _firstNonEmpty([place.country]);
        if (city.isNotEmpty || country.isNotEmpty) {
          return (city: city, country: country);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[LocationService] geocoding error: $e');
      return null;
    }
  }

  static Future<LocationPermission> currentPermission() {
    return Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() {
    debugPrint('[LocationService] requestPermission()');
    return Geolocator.requestPermission();
  }

  /// Checks permission and optionally shows the system dialog when denied.
  static Future<LocationPermission> ensurePermission({
    bool requestIfDenied = false,
  }) async {
    var permission = await Geolocator.checkPermission();
    debugPrint('[LocationService] ensurePermission initial: $permission');

    if (isPermissionGranted(permission)) return permission;
    if (permission == LocationPermission.deniedForever) return permission;
    if (!requestIfDenied || !isPermissionDenied(permission)) {
      return permission;
    }

    permission = await Geolocator.requestPermission();
    debugPrint('[LocationService] ensurePermission after request: $permission');
    return permission;
  }

  static Future<LocationResolveResult> permissionOnlyResult(
    LocationPermission permission,
  ) async {
    if (permission == LocationPermission.deniedForever) {
      return const LocationResolveResult(
        state: LocationResolveState.deniedForever,
      );
    }
    if (isPermissionDenied(permission)) {
      return const LocationResolveResult(state: LocationResolveState.denied);
    }
    return const LocationResolveResult(state: LocationResolveState.pending);
  }

  static Future<({Position? position, LocationSource source})>
      _resolvePosition() async {
    Future<Position?> tryFix(LocationSettings settings) async {
      try {
        return await Geolocator.getCurrentPosition(locationSettings: settings);
      } catch (e) {
        debugPrint('[LocationService] getCurrentPosition failed: $e');
        return null;
      }
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      debugPrint(
        '[LocationService] lastKnown lat=${lastKnown.latitude} '
        'lon=${lastKnown.longitude}',
      );
    }

    Position? position = await tryFix(
      const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    position ??= lastKnown;

    if (position == null && !kIsWeb && Platform.isAndroid) {
      position = await tryFix(
        AndroidSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 8),
          forceLocationManager: true,
        ),
      );
    }

    position ??= await tryFix(
      const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );

    position ??= lastKnown;

    if (position != null) {
      final source = _classifyPosition(position);
      debugPrint(
        '[LocationService] position lat=${position.latitude} '
        'lon=${position.longitude} source=$source mocked=${position.isMocked}',
      );
      return (position: position, source: source);
    }

    return (position: null, source: LocationSource.unavailable);
  }

  static Future<LocationResolveResult> _fetchAfterPermissionGranted() async {
    final resolved = await _resolvePosition().timeout(
      _positionTimeout,
      onTimeout: () {
        debugPrint('[LocationService] position fetch timed out');
        return (position: null, source: LocationSource.unavailable);
      },
    );

    final pos = resolved.position;
    final posSource = resolved.source;

    if (pos == null) {
      return const LocationResolveResult(
        state: LocationResolveState.unavailable,
        source: LocationSource.unavailable,
      );
    }

    final region = _coordinatesToRegion(pos.latitude, pos.longitude);
    final place = await _reverseGeocode(pos.latitude, pos.longitude);

    if (place != null) {
      return LocationResolveResult(
        state: LocationResolveState.success,
        source: posSource,
        location: UserLocation(
          city: place.city,
          country: place.country,
          marketRegion: region,
          source: posSource,
          positionTime: pos.timestamp,
        ),
      );
    }

    final approxCountry = _approxCountryFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (approxCountry.isNotEmpty) {
      return LocationResolveResult(
        state: LocationResolveState.success,
        source: posSource,
        location: UserLocation(
          city: '',
          country: approxCountry,
          marketRegion: region,
          source: posSource,
          positionTime: pos.timestamp,
        ),
      );
    }

    return LocationResolveResult(
      state: LocationResolveState.geocodeFailed,
      source: posSource,
      location: UserLocation(
        city: '',
        country: '',
        marketRegion: region,
        source: posSource,
        positionTime: pos.timestamp,
      ),
    );
  }

  static Future<LocationResolveResult> fetchLocationAfterPermissionGranted() async {
    try {
      return await _fetchAfterPermissionGranted().timeout(
        _fetchTimeout,
        onTimeout: () {
          debugPrint('[LocationService] fetch timed out');
          return const LocationResolveResult(
            state: LocationResolveState.unavailable,
            source: LocationSource.unavailable,
          );
        },
      );
    } catch (e) {
      debugPrint('[LocationService] fetch error: $e');
      return const LocationResolveResult(
        state: LocationResolveState.unavailable,
        source: LocationSource.unavailable,
      );
    }
  }

  /// Permission + service gate only — no GPS fetch, finishes quickly.
  static Future<LocationResolveResult> resolveAccess({
    bool requestIfDenied = false,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[LocationService] locationServiceEnabled: $serviceEnabled');
      if (!serviceEnabled) {
        return const LocationResolveResult(
          state: LocationResolveState.serviceDisabled,
        );
      }

      final permission = await ensurePermission(
        requestIfDenied: requestIfDenied,
      );

      if (permission == LocationPermission.deniedForever) {
        return const LocationResolveResult(
          state: LocationResolveState.deniedForever,
        );
      }
      if (isPermissionDenied(permission)) {
        return const LocationResolveResult(state: LocationResolveState.denied);
      }

      return const LocationResolveResult(state: LocationResolveState.pending);
    } catch (e) {
      debugPrint('[LocationService] resolveAccess error: $e');
      return const LocationResolveResult(
        state: LocationResolveState.unavailable,
        source: LocationSource.unavailable,
      );
    }
  }

  static Future<LocationResolveResult> resolveCurrentLocation({
    bool requestPermissionIfDenied = false,
  }) async {
    try {
      final access = await resolveAccess(
        requestIfDenied: requestPermissionIfDenied,
      );
      if (access.state != LocationResolveState.pending) {
        return access;
      }

      if (requestPermissionIfDenied) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      return fetchLocationAfterPermissionGranted();
    } catch (e) {
      debugPrint('[LocationService] resolve error: $e');
      return const LocationResolveResult(
        state: LocationResolveState.unavailable,
        source: LocationSource.unavailable,
      );
    }
  }
}
