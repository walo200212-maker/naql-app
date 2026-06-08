import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DistanceCalculator {
  /// Haversine formula for straight-line distance in km
  static double calculateKm(LatLng from, LatLng to) {
    const earthRadius = 6371.0;
    final dLat = _toRad(to.latitude - from.latitude);
    final dLon = _toRad(to.longitude - from.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(from.latitude)) *
            cos(_toRad(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  /// Estimate job price based on truck type price per km
  static double estimatePrice(double distanceKm, double pricePerKm) {
    return distanceKm * pricePerKm;
  }

  /// Commission deducted from driver wallet
  static double calculateCommission(double jobPrice) {
    return jobPrice * 0.12;
  }
}
