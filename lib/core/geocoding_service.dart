import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  // THE FIX: Define your beta test town here so OSM doesn't default to Athens.
  static const String betaTown = "Veria"; // e.g., "Chania", "Volos", "Kavala"

  static Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      // Intelligently build the query so the user doesn't have to type the town or country
      String query = address;

      if (!query.toLowerCase().contains(betaTown.toLowerCase())) {
        query = '$query, $betaTown';
      }
      if (!query.toLowerCase().contains('greece')) {
        query = '$query, Greece';
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'gr',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'CraveApp/1.0',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] ?? '');
      final lng = double.tryParse(first['lon'] ?? '');

      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    } catch (_) {
      return null;
    }
  }
}