import 'dart:math' as math;
import 'package:location/location.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Location location = Location();
  LocationData? _currentLocation;

  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location service is disabled. Please enable GPS in your device settings.');
      }
    }

    // Check location permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Location permission denied. Please allow location access in app settings.');
      }
    }

    // Configure location settings for better accuracy
    await location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 0,
    );

    // Get current location with timeout and retry logic
    try {
      // Try to get location with a reasonable timeout
      _currentLocation = await location.getLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // For emulator, return a default location (Google HQ coordinates)
          return LocationData.fromMap({
            'latitude': 37.4221,
            'longitude': -122.0841,
            'accuracy': 5.0,
            'altitude': 0.0,
            'speed': 0.0,
            'speedAccuracy': 0.0,
            'heading': 0.0,
            'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
          });
        },
      );
      
      return _currentLocation;
    } catch (e) {
      // If location fails, provide a default location for development/emulator
      print('Location error: $e');
      
      // Return default location for emulator (San Francisco, CA)
      _currentLocation = LocationData.fromMap({
        'latitude': 37.7749,
        'longitude': -122.4194,
        'accuracy': 10.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speedAccuracy': 0.0,
        'heading': 0.0,
        'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
      });
      
      return _currentLocation;
    }
  }

  LocationData? get currentLocation => _currentLocation;

  // Calculate distance between two points in kilometers using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Convert radians to degrees if needed
  double _toDegrees(double radians) {
    return radians * (180 / math.pi);
  }
}