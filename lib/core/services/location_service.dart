import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class LocationService {
  final Logger _logger = Logger();

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled.');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _logger.i('Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      _logger.e('Error getting current location: $e');
      return null;
    }
  }

  /// Get location coordinates as string format
  Future<String?> getCurrentLocationString() async {
    final position = await getCurrentLocation();
    if (position != null) {
      return '${position.latitude},${position.longitude}';
    }
    return null;
  }

  /// Get approximate city name from coordinates (simplified)
  /// Note: This is a basic implementation. For production, consider using geocoding package
  Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
    // For now, return coordinates as string since geocoding requires additional package
    // In production, add geocoding package and implement proper reverse geocoding
    return '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
  }

  /// Get user's current city
  Future<String?> getCurrentCity() async {
    final position = await getCurrentLocation();
    if (position != null) {
      return await getCityFromCoordinates(position.latitude, position.longitude);
    }
    return null;
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
}

// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Provider for current user location
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

// Provider for current user city
final currentCityProvider = FutureProvider<String?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentCity();
});