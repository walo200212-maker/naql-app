import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String displayName;
  final String shortName;
  final double lat;
  final double lng;

  const PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lng,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final full = (json['display_name'] as String? ?? '').trim();
    final parts = full
        .split(',')
        .map((e) => e.trim())
        .where((e) =>
            e.isNotEmpty &&
            e != 'المغرب' &&
            e != 'Maroc' &&
            e != 'Morocco')
        .toList();
    final short = parts.take(2).join('، ');
    return PlaceSuggestion(
      displayName: full,
      shortName: short.isNotEmpty ? short : full,
      lat: double.tryParse(json['lat'] as String? ?? '0') ?? 0,
      lng: double.tryParse(json['lon'] as String? ?? '0') ?? 0,
    );
  }
}

class GeocodingService {
  static const _base = 'https://nominatim.openstreetmap.org';

  Future<List<PlaceSuggestion>> searchMorocco(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final uri = Uri.parse('$_base/search').replace(queryParameters: {
        'q': query,
        'countrycodes': 'ma',
        'format': 'json',
        'limit': '5',
        'accept-language': 'ar,fr',
      });
      final response = await http
          .get(uri, headers: {
            'User-Agent': 'WaslApp/1.0 Morocco moving marketplace',
          })
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
