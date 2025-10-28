import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DirectionsService {
  // Tu token de Mapbox (el mismo que usas en el mapa)
  static const String _mapboxToken = 
      'pk.eyJ1Ijoic2hhbmRlYzA2IiwiYSI6ImNtZzJpMmpreTB5c2gyam9pdXZsa29ucnUifQ.ewvvU-PI7KGZaim9v8tbBA';

  /// Obtiene la ruta entre dos puntos usando Mapbox Directions API
  static Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=geojson'
        '&access_token=$_mapboxToken',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convertir coordenadas [lng, lat] a LatLng
          return coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();
        }
      }

      print('Error en Directions API: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error obteniendo ruta: $e');
      return [];
    }
  }
}