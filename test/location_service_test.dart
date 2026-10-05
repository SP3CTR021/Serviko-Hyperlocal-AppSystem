import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/location_service.dart';

void main() {
  group('LocationService Proximity & Davao Barangays Tests', () {
    final locationService = LocationService();

    test('Resolves Maa, Davao City coordinates accurately', () {
      final maa = locationService.resolveLocationSync('Maa, Davao City');
      expect(maa.latitude, closeTo(7.0736, 0.001));
      expect(maa.longitude, closeTo(125.5861, 0.001));
    });

    test('Calculates Haversine distance from Maa to neighboring barangays', () {
      final maa = locationService.resolveLocationSync('Maa, Davao City');
      final matina = locationService.resolveLocationSync('Matina, Davao City');
      final buhangin = locationService.resolveLocationSync('Buhangin, Davao City');
      final toril = locationService.resolveLocationSync('Toril, Davao City');
      final calinan = locationService.resolveLocationSync('Calinan, Davao City');
      final marilog = locationService.resolveLocationSync('Marilog, Davao City');

      final distMatina = locationService.calculateDistanceKm(
        maa.latitude, maa.longitude, matina.latitude, matina.longitude,
      );
      final distBuhangin = locationService.calculateDistanceKm(
        maa.latitude, maa.longitude, buhangin.latitude, buhangin.longitude,
      );
      final distToril = locationService.calculateDistanceKm(
        maa.latitude, maa.longitude, toril.latitude, toril.longitude,
      );
      final distCalinan = locationService.calculateDistanceKm(
        maa.latitude, maa.longitude, calinan.latitude, calinan.longitude,
      );
      final distMarilog = locationService.calculateDistanceKm(
        maa.latitude, maa.longitude, marilog.latitude, marilog.longitude,
      );

      // Within 15km radius
      expect(distMatina, lessThan(15.0)); // ~1.7 km
      expect(distBuhangin, lessThan(15.0)); // ~5.1 km
      expect(distToril, lessThan(15.0)); // ~11.1 km

      // Outside 15km radius
      expect(distCalinan, greaterThan(15.0)); // ~19.0 km
      expect(distMarilog, greaterThan(15.0)); // ~54.0 km
    });

    test('Proximity filtering strictly filters at 15km radius', () {
      final maa = locationService.resolveLocationSync('Maa, Davao City');

      final sampleLocations = [
        'Maa, Davao City',
        'Matina, Davao City',
        'Agdao, Davao City',
        'Buhangin, Davao City',
        'Lanang, Davao City',
        'Toril, Davao City',
        'Calinan, Davao City',
        'Marilog, Davao City',
      ];

      final within15Km = sampleLocations.where((loc) {
        final pt = locationService.resolveLocationSync(loc);
        final d = locationService.calculateDistanceKm(
          maa.latitude, maa.longitude, pt.latitude, pt.longitude,
        );
        return d <= 15.0;
      }).toList();

      expect(within15Km.contains('Maa, Davao City'), isTrue);
      expect(within15Km.contains('Matina, Davao City'), isTrue);
      expect(within15Km.contains('Toril, Davao City'), isTrue);
      expect(within15Km.contains('Calinan, Davao City'), isFalse);
      expect(within15Km.contains('Marilog, Davao City'), isFalse);
    });
  });
}
