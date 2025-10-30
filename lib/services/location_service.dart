import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static LatLng? _lastKnownLocation;

  /// Solicita permisos de ubicación
  static Future<bool> requestPermission() async {
    try {
      // 1. Verificar si el servicio está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Servicio de ubicación deshabilitado');
        return false;
      }

      // 2. Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        print('⚠️ Solicitando permisos...');
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          print('❌ Permisos denegados');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permisos denegados permanentemente');
        return false;
      }

      print('✅ Permisos concedidos');
      return true;
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }

  /// Obtiene la ubicación actual
  static Future<LatLng?> getCurrentLocation() async {
    try {
      print('📍 Obteniendo ubicación...');
      
      // Verificar permisos
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('⚠️ Sin permisos de ubicación');
        return _lastKnownLocation;
      }

      // Intentar obtener ubicación actual con timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10), // ✅ Timeout de 10 segundos
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () async {
          print('⏱️ Timeout - Intentando última ubicación conocida...');
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            return lastPosition;
          }
          throw Exception('No se pudo obtener ubicación');
        },
      );

      final location = LatLng(position.latitude, position.longitude);
      _lastKnownLocation = location;
      
      print('✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      return location;
      
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      
      // Intentar obtener última ubicación conocida como fallback
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          final location = LatLng(lastPosition.latitude, lastPosition.longitude);
          _lastKnownLocation = location;
          print('✅ Usando última ubicación conocida');
          return location;
        }
      } catch (e2) {
        print('❌ Error obteniendo última ubicación: $e2');
      }
      
      return _lastKnownLocation;
    }
  }

  /// Stream de ubicación en tiempo real
  static Stream<LatLng> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) {
          final location = LatLng(position.latitude, position.longitude);
          _lastKnownLocation = location;
          print('📍 Ubicación actualizada: ${position.latitude}, ${position.longitude}');
          return location;
        })
        .handleError((error) {
          print('❌ Error en stream de ubicación: $error');
        });
  }

  /// Verifica si tiene permisos concedidos
  static Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }
}