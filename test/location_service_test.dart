import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:clarivo/services/location_service.dart';

void main() {
  group('LocationService permission helpers', () {
    test('isPermissionGranted', () {
      expect(
        LocationService.isPermissionGranted(LocationPermission.whileInUse),
        isTrue,
      );
      expect(
        LocationService.isPermissionGranted(LocationPermission.always),
        isTrue,
      );
      expect(
        LocationService.isPermissionGranted(LocationPermission.denied),
        isFalse,
      );
    });

    test('isPermissionDenied includes unableToDetermine', () {
      expect(
        LocationService.isPermissionDenied(LocationPermission.denied),
        isTrue,
      );
      expect(
        LocationService.isPermissionDenied(LocationPermission.unableToDetermine),
        isTrue,
      );
      expect(
        LocationService.isPermissionDenied(LocationPermission.whileInUse),
        isFalse,
      );
    });

    test('permissionOnlyResult maps denied states', () async {
      expect(
        (await LocationService.permissionOnlyResult(
          LocationPermission.denied,
        ))
            .state,
        LocationResolveState.denied,
      );
      expect(
        (await LocationService.permissionOnlyResult(
          LocationPermission.deniedForever,
        ))
            .state,
        LocationResolveState.deniedForever,
      );
    });
  });
}
