import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class GeoPoint {
  final double latitude;
  final double longitude;
  final String displayName;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // In-memory geocode cache to prevent redundant lookups
  final Map<String, GeoPoint> _cache = {};

  // Pre-mapped coordinates for Davao City Barangays & Districts (0ms latency, 100% offline)
  static const Map<String, ({double lat, double lng})> davaoBarangayCoords = {
    'maa': (lat: 7.0736, lng: 125.5861),
    'ma-a': (lat: 7.0736, lng: 125.5861),
    'matina': (lat: 7.0583, lng: 125.5828),
    'matina crossing': (lat: 7.0583, lng: 125.5828),
    'matina aplaya': (lat: 7.0490, lng: 125.5780),
    'bucana': (lat: 7.0601, lng: 125.6080),
    'poblacion': (lat: 7.0731, lng: 125.6128),
    'davao city': (lat: 7.0731, lng: 125.6128),
    'buhangin': (lat: 7.1083, lng: 125.6167),
    'agdao': (lat: 7.0858, lng: 125.6267),
    'lanang': (lat: 7.1044, lng: 125.6415),
    'talomo': (lat: 7.0450, lng: 125.5560),
    'bangkal': (lat: 7.0540, lng: 125.5680),
    'mintal': (lat: 7.0911, lng: 125.5297),
    'toril': (lat: 7.0203, lng: 125.5019),
    'sasa': (lat: 7.1264, lng: 125.6617),
    'cabantian': (lat: 7.1350, lng: 125.6250),
    'panacan': (lat: 7.1492, lng: 125.6606),
    'tibungco': (lat: 7.1858, lng: 125.6592),
    'bunawan': (lat: 7.2289, lng: 125.6511),
    'calinan': (lat: 7.1856, lng: 125.4578),
    'catalunan grande': (lat: 7.0789, lng: 125.5394),
    'catalunan pequeno': (lat: 7.0592, lng: 125.5283),
    'bago aplaya': (lat: 7.0319, lng: 125.5392),
    'tugbok': (lat: 7.1056, lng: 125.4986),
    'mandug': (lat: 7.1667, lng: 125.5833),
    'indangan': (lat: 7.1500, lng: 125.6167),
    'marilog': (lat: 7.4500, lng: 125.2667),
    'paquibato': (lat: 7.3667, lng: 125.5667),
    'sta. ana': (lat: 7.0792, lng: 125.6214),
    'bajada': (lat: 7.0880, lng: 125.6180),
    'obrero': (lat: 7.0830, lng: 125.6190),
    'ecoland': (lat: 7.0550, lng: 125.5950),
    'langub': (lat: 7.0850, lng: 125.5600),
    'magtuod': (lat: 7.0950, lng: 125.5750),
    'waan': (lat: 7.1200, lng: 125.5700),
    'tigatto': (lat: 7.1300, lng: 125.5900),
  };

  /// Calculates straight-line distance in kilometers between two GPS coordinates using Haversine formula
  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * Earth radius (6,371 km)
  }

  /// Resolves an address or barangay string to GeoPoint.
  /// First checks the local Davao dictionary, then falls back to OpenStreetMap Nominatim API.
  Future<GeoPoint> resolveLocation(String rawLocation) async {
    final clean = rawLocation.trim().toLowerCase();
    if (_cache.containsKey(clean)) {
      return _cache[clean]!;
    }

    // 1. Check local Davao City dictionary (specific barangays first, longer keys first)
    final barangayEntries = davaoBarangayCoords.entries
        .where((e) => e.key != 'davao city')
        .toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in barangayEntries) {
      if (clean.contains(entry.key)) {
        final gp = GeoPoint(
          latitude: entry.value.lat,
          longitude: entry.value.lng,
          displayName: rawLocation,
        );
        _cache[clean] = gp;
        return gp;
      }
    }

    if (clean.contains('davao city')) {
      final gp = GeoPoint(
        latitude: davaoBarangayCoords['davao city']!.lat,
        longitude: davaoBarangayCoords['davao city']!.lng,
        displayName: rawLocation,
      );
      _cache[clean] = gp;
      return gp;
    }

    // 2. Query OpenStreetMap Nominatim API for external / custom Philippine addresses
    try {
      final query = Uri.encodeComponent('$rawLocation, Philippines');
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');

      final client = HttpClient();
      client.userAgent = 'Serviko-App/1.0 (contact@serviko.ph)';
      final request = await client.getUrl(url).timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(responseBody);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString()) ?? 7.0736;
          final lon = double.tryParse(data[0]['lon'].toString()) ?? 125.5861;
          final gp = GeoPoint(latitude: lat, longitude: lon, displayName: data[0]['display_name'] ?? rawLocation);
          _cache[clean] = gp;
          return gp;
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Nominatim fallback note: $e');
    }

    // Default fallback: Maa, Davao City Center
    const fallback = GeoPoint(
      latitude: 7.0736,
      longitude: 125.5861,
      displayName: 'Maa, Davao City',
    );
    _cache[clean] = fallback;
    return fallback;
  }

  /// Synchronous fast coordinate resolver using local database
  GeoPoint resolveLocationSync(String rawLocation) {
    final clean = rawLocation.trim().toLowerCase();
    if (_cache.containsKey(clean)) {
      return _cache[clean]!;
    }

    // Specific barangays first, longer keys first
    final barangayEntries = davaoBarangayCoords.entries
        .where((e) => e.key != 'davao city')
        .toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in barangayEntries) {
      if (clean.contains(entry.key)) {
        final gp = GeoPoint(
          latitude: entry.value.lat,
          longitude: entry.value.lng,
          displayName: rawLocation,
        );
        _cache[clean] = gp;
        return gp;
      }
    }

    if (clean.contains('davao city')) {
      final gp = GeoPoint(
        latitude: davaoBarangayCoords['davao city']!.lat,
        longitude: davaoBarangayCoords['davao city']!.lng,
        displayName: rawLocation,
      );
      _cache[clean] = gp;
      return gp;
    }

    // Default to Maa, Davao City
    return const GeoPoint(
      latitude: 7.0736,
      longitude: 125.5861,
      displayName: 'Maa, Davao City',
    );
  }
}
