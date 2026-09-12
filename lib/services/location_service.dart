import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (!serviceEnabled || permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<bool> hasLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    if (permission == LocationPermission.denied) {
      debugPrint('Location permission denied');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    return true;
  }

  Future<LocationPermission> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled. Please enable them.');
        return LocationPermission.denied;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
        }
      }

      return permission;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Format address components into a readable string
        final addressParts = [
          if (place.street?.isNotEmpty ?? false) place.street,
          if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
          if (place.locality?.isNotEmpty ?? false) place.locality,
          if (place.postalCode?.isNotEmpty ?? false) place.postalCode,
          if (place.administrativeArea?.isNotEmpty ?? false)
            place.administrativeArea,
          if (place.country?.isNotEmpty ?? false) place.country,
        ];
        return addressParts.where((part) => part != null).join(', ');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address from coordinates ($lat, $lon): $e');
      return null;
    }
  }

  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates from address "$address": $e');
      return null;
    }
  }

  Future<double> calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return 0.0;
    }
  }

  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Geolocator.getPositionStream(
      locationSettings:
          locationSettings ??
          const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 100,
          ),
    );
  }

  Future<bool> isLocationWithinBounds(
    double lat,
    double lon,
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  ) async {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

  Future<String?> getCurrentCity() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return null;

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ??
            placemarks.first.subAdministrativeArea;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current city: $e');
      return null;
    }
  }

  Future<String?> getCurrentCountry() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return null;

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.country;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current country: $e');
      return null;
    }
  }

  Future<Map<String, String>?> getCurrentLocationDetails() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return null;

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      return {
        'street': place.street ?? '',
        'sublocality': place.subLocality ?? '',
        'locality': place.locality ?? '',
        'administrativeArea': place.administrativeArea ?? '',
        'postalCode': place.postalCode ?? '',
        'country': place.country ?? '',
        'isoCountryCode': place.isoCountryCode ?? '',
        'thoroughfare': place.thoroughfare ?? '',
        'subThoroughfare': place.subThoroughfare ?? '',
      };
    } catch (e) {
      debugPrint('Error getting location details: $e');
      return null;
    }
  }

  Future<double> getAltitude() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return position.altitude;
    } catch (e) {
      debugPrint('Error getting altitude: $e');
      return 0.0;
    }
  }

  Future<double> getSpeed() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return position.speed;
    } catch (e) {
      debugPrint('Error getting speed: $e');
      return 0.0;
    }
  }

  Future<DateTime?> getLocationTimestamp() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return DateTime.fromMillisecondsSinceEpoch(
        position.timestamp.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error getting location timestamp: $e');
      return null;
    }
  }
}
