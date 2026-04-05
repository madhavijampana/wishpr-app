import 'package:geolocator/geolocator.dart';

import 'permission_service.dart';

/// One-shot location read (used after iOS/Android location permission flows).
abstract class WishprLocationCapturing {
  Future<LocationCaptureOutcome> captureCurrentLocation({
    required PermissionService permissionService,
  });
}

/// Captures a one-shot GPS fix after permissions and services are OK.
class WishprLocationService implements WishprLocationCapturing {
  const WishprLocationService();

  @override
  Future<LocationCaptureOutcome> captureCurrentLocation({
    required PermissionService permissionService,
  }) async {
    var perm = await permissionService.status(WishprPermission.locationWhenInUse);
    if (!permissionService.isAllowed(perm)) {
      perm = await permissionService.request(WishprPermission.locationWhenInUse);
    }
    if (!permissionService.isAllowed(perm)) {
      return LocationCaptureOutcome.failure(
        'Location permission is required to share your position.',
      );
    }

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return LocationCaptureOutcome.failure(
        'Location is off. Turn on location services and try again.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationCaptureOutcome.success(position);
    } catch (e) {
      return LocationCaptureOutcome.failure(
        'Could not read GPS: ${e.toString()}',
      );
    }
  }
}

class LocationCaptureOutcome {
  const LocationCaptureOutcome._({this.position, this.errorMessage});

  final Position? position;
  final String? errorMessage;

  bool get isSuccess => position != null;

  factory LocationCaptureOutcome.success(Position position) {
    return LocationCaptureOutcome._(position: position);
  }

  factory LocationCaptureOutcome.failure(String message) {
    return LocationCaptureOutcome._(errorMessage: message);
  }
}
