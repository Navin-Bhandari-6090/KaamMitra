// ---------------------------------------------------------------------------
// Add to pubspec.yaml if not already present:
//   geolocator: ^13.0.0   (or whatever the latest 13.x/14.x release is)
//
// Platform notes (see the geolocator README you pasted):
//   - Web: requires HTTPS (or localhost) and will show the browser's native
//     "Allow location access?" prompt. checkPermission() can report
//     `denied` on browsers that don't support the Permissions API even
//     when the user would still be prompted — that's expected, the flow
//     below still works because requestPermission()/getCurrentPosition()
//     trigger the native prompt regardless.
//   - Android/iOS: make sure the platform-specific permission entries from
//     the README (location usage strings on iOS, permissions on Android)
//     are in place.
// ---------------------------------------------------------------------------

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../../web/common widget/toast.dart';

// Adjust the relative import segment count above to match wherever you
// place this file — nothing else in it depends on folder depth.

/// The specific reason a location fetch failed, so callers (or
/// [GetLocationGetx] below) can react differently — e.g. opening the
/// right settings screen — instead of just showing a generic message.
enum LocationFailureType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// Thrown by [GetLocation] when the location service or permissions
/// prevent a fix. `message` is written to be shown directly to the user
/// (via a toast, snackbar, whatever the calling screen already uses).
class LocationFailure implements Exception {
  final String message;
  final LocationFailureType type;

  const LocationFailure(this.message, this.type);

  @override
  String toString() => message;
}

/// ---------------------------------------------------------------------------
/// PLAIN, GetX-FREE LOCATION SERVICE
/// No controller, no widget, no state — just a function you can call from
/// anywhere in the app (a GetX controller, a plain Dart service, another
/// screen entirely) to get the device's live coordinates. This is the
/// "flexible / usable anywhere" piece; [GetLocationGetx] below is just one
/// convenience wrapper around it for screens that want reactive state.
/// ---------------------------------------------------------------------------
class GetLocation {
  const GetLocation();

  /// Runs the full "check service -> check permission -> request
  /// permission -> get position" flow recommended by the geolocator
  /// package, and throws a [LocationFailure] with a user-friendly message
  /// (and a [LocationFailureType] so callers can react appropriately) at
  /// whichever step fails, instead of a raw platform exception.
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        "Location services are turned off. Please enable them and try again.",
        LocationFailureType.serviceDisabled,
      );
    }

    // This is the actual "ask" step — checkPermission alone never prompts
    // anything; requestPermission is what triggers the native OS/browser
    // permission dialog when the current status is `denied`.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationFailure(
          "Location permission denied. Allow access to use your live location.",
          LocationFailureType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        "Location permission is permanently denied. Enable it from your "
            "browser or device settings, then try again.",
        LocationFailureType.permissionDeniedForever,
      );
    }

    try {
      final LocationSettings locationSettings = LocationSettings(
        accuracy: accuracy,
      );

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(
        timeLimit,
        onTimeout: () => throw const LocationFailure(
          "Timed out while getting your location. Please try again.",
          LocationFailureType.timeout,
        ),
      );
    } on LocationFailure {
      rethrow;
    } catch (e) {
      throw LocationFailure(
        "Couldn't get your location: $e",
        LocationFailureType.unknown,
      );
    }
  }

  /// Opens the device's location-services settings screen. Used when the
  /// service itself is turned off (not a permission problem). May be a
  /// no-op on some platforms (notably web) — always wrap in try/catch.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens the app's own settings screen, where a "permanently denied"
  /// permission can be re-granted. May be a no-op on some platforms
  /// (notably web) — always wrap in try/catch.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

/// ---------------------------------------------------------------------------
/// GETX WRAPPER
/// Thin reactive layer around [GetLocation] for screens that want a loading
/// flag + the last-fetched lat/long as Rx state, without every screen
/// re-writing the same try/catch/toast boilerplate.
///
/// Put with a per-screen tag (same pattern as ChangeLocationGetx /
/// ChangePhotoGetx / etc.) so multiple screens can each hold their own
/// independent instance:
///
///   final locationCont = Get.put(GetLocationGetx(), tag: myTag);
///   ...
///   Get.delete<GetLocationGetx>(tag: myTag); // in dispose()
/// ---------------------------------------------------------------------------
class GetLocationGetx extends GetxController {
  final Toast = Toastget();
  final GetLocation _service = const GetLocation();

  final RxBool isFetchingLocation = false.obs;
  final Rxn<double> latitude = Rxn<double>();
  final Rxn<double> longitude = Rxn<double>();

  /// Fetches the device's live location and stores it in [latitude] /
  /// [longitude]. Returns true on success so callers can react (e.g. fill
  /// text fields) right after awaiting this, without reading Rx values
  /// inside a build method.
  ///
  /// On failure this always shows a toast explaining what went wrong, and
  /// additionally:
  ///   - if location services are off, opens the device's location
  ///     settings screen so the person can flip it on directly;
  ///   - if permission was permanently denied, opens the app's settings
  ///     screen so the person can re-grant it directly.
  /// (Both settings calls are best-effort — some platforms, notably web,
  /// don't support them, so failures there are swallowed silently and the
  /// toast message is the fallback guidance.)
  Future<bool> fetchCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    if (isFetchingLocation.value) return false;

    isFetchingLocation.value = true;
    try {
      final position = await _service.getCurrentPosition(accuracy: accuracy);
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      return true;
    } on LocationFailure catch (e) {
      Toast.Toastmsg(e.message);

      switch (e.type) {
        case LocationFailureType.serviceDisabled:
          try {
            await _service.openLocationSettings();
          } catch (_) {
            // Not supported on this platform (e.g. web) — the toast above
            // already told the person what to do manually.
          }
          break;
        case LocationFailureType.permissionDeniedForever:
          try {
            await _service.openAppSettings();
          } catch (_) {
            // Same as above — best-effort only.
          }
          break;
        case LocationFailureType.permissionDenied:
        case LocationFailureType.timeout:
        case LocationFailureType.unknown:
        // requestPermission() already showed the native prompt for the
        // "denied" case — nothing further to open here.
          break;
      }

      return false;
    } catch (e) {
      Toast.Toastmsg("Couldn't get your location. Try again.");
      return false;
    } finally {
      if (!isClosed) isFetchingLocation.value = false;
    }
  }

  void clear() {
    latitude.value = null;
    longitude.value = null;
  }
}