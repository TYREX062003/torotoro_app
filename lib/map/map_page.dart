import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../services/tts_service.dart';
import '../services/locale_service.dart';
import '../services/content_translation_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _center = LatLng(-18.1325, -65.7683);
  static const String _mapboxToken =
      'pk.eyJ1Ijoic2hhbmRlYzA2IiwiYSI6ImNtZzJpMmpreTB5c2gyam9pdXZsa29ucnUifQ.ewvvU-PI7KGZaim9v8tbBA';

  final MapController _mapController = MapController();
  final TtsService _ttsService = TtsService();
  final LocaleService _localeService = LocaleService();
  final ContentTranslationService _translationService = ContentTranslationService();

  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _isLoadingLocation = true; // ✅ NUEVO: Estado de carga
  String? _estimatedTime;
  String? _estimatedDistance;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeService.removeListener(_onLocaleChanged);
    _ttsService.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  /// ✅ CORREGIDO: Mejor manejo de ubicación inicial
  Future<void> _initLocation() async {
    print('🗺️ Inicializando ubicación...');
    
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      // Intentar obtener ubicación actual
      final location = await LocationService.getCurrentLocation();
      
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
        });
        print('✅ Ubicación inicial establecida');
        
        // Centrar mapa en la ubicación
        _mapController.move(location, 14);
      } else {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          print('⚠️ No se pudo obtener ubicación inicial');
          
          // Mostrar mensaje al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se pudo obtener tu ubicación. Verifica los permisos.'),
              action: SnackBarAction(
                label: 'Reintentar',
                onPressed: () => _initLocation(),
              ),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // ✅ Escuchar actualizaciones de ubicación en tiempo real
      LocationService.getLocationStream().listen(
        (location) {
          if (mounted) {
            setState(() => _currentLocation = location);
            print('📍 Ubicación actualizada en mapa');
          }
        },
        onError: (error) {
          print('❌ Error en stream de ubicación: $error');
        },
      );
    } catch (e) {
      print('❌ Error inicializando ubicación: $e');
      
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _goToLocation(LatLng destination) async {
    final l10n = AppLocalizations.of(context)!;

    if (_currentLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locationNotAvailable),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=geojson&access_token=$_mapboxToken',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final duration = route['duration'] as num;
          final distance = route['distance'] as num;

          final routePoints = coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          setState(() {
            _routePoints = routePoints;
            _estimatedTime = _formatDuration(duration.toInt());
            _estimatedDistance = _formatDistance(distance.toDouble());
          });

          final bounds = LatLngBounds.fromPoints([_currentLocation!, destination]);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
          );

          if (!mounted) return;
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final poisStream = FirebaseFirestore.instance.collection('pois').snapshots();
    final lang = _localeService.simpleLanguageCode;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: poisStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final markers = <Marker>[];

                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  for (final doc in snap.data!.docs) {
                    final data = doc.data();
                    try {
                      final lat = (data['lat'] as num).toDouble();
                      final lng = (data['lng'] as num).toDouble();
                      final poiLocation = LatLng(lat, lng);

                      final translatedName = _translationService.poiNameFromDoc(data, lang);
                      final imageUrl = (data['imageUrl'] ?? data['coverUrl'] ?? '').toString();
                      final displayName = translatedName.isEmpty ? doc.id : translatedName;

                      markers.add(
                        Marker(
                          point: poiLocation,
                          width: 60,
                          height: 60,
                          child: IconButton(
                            icon: const Icon(Icons.location_on, size: 40, color: Colors.red),
                            tooltip: displayName,
                            onPressed: () => _showPoiSheet(
                              context,
                              doc.id,
                              data,
                              imageUrl,
                              poiLocation,
                            ),
                          ),
                        ),
                      );
                    } catch (_) {}
                  }
                }

                // ✅ Marcador de ubicación actual
                if (_currentLocation != null) {
                  markers.add(
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                      ),
                    ),
                  );
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? _center,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                      additionalOptions: const {'accessToken': _mapboxToken},
                      userAgentPackageName: 'com.torotoro.torotoro_app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue,
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
            ),

            // ✅ Indicador de carga de ubicación
            if (_isLoadingLocation)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Obteniendo ubicación...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ Info de ruta
            if (_estimatedTime != null && _estimatedDistance != null)
              Positioned(
                bottom: 120,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Color(0xFF6B7C3F)),
                      const SizedBox(width: 6),
                      Text(_estimatedTime!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 16, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      const Icon(Icons.straighten, size: 18, color: Color(0xFF6B7C3F)),
                      const SizedBox(width: 6),
                      Text(_estimatedDistance!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Botón "Mi ubicación"
          if (_currentLocation != null)
            FloatingActionButton(
              heroTag: 'my_location',
              onPressed: () {
                _mapController.move(_currentLocation!, 15);
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location),
            ),
          const SizedBox(height: 10),
          
          // ✅ Botón para limpiar ruta
          if (_routePoints.isNotEmpty)
            FloatingActionButton(
              heroTag: 'clear_route',
              onPressed: () {
                setState(() {
                  _routePoints = [];
                  _estimatedTime = null;
                  _estimatedDistance = null;
                });
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  void _showPoiSheet(
    BuildContext context,
    String poiId,
    Map<String, dynamic> data,
    String imageUrl,
    LatLng location,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final lang = _localeService.simpleLanguageCode;

    final translatedName = _translationService.poiNameFromDoc(data, lang);
    final translatedDesc = _translationService.poiDescFromDoc(data, lang);
    final displayName = translatedName.isEmpty ? poiId : translatedName;

    _ttsService.stop();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (_, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE0E0E0),
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 32, color: Colors.black38),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (imageUrl.isNotEmpty) const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B4636),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.pointOfInterest,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _ttsService.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                          color: _ttsService.isSpeaking ? const Color(0xFF6B7C3F) : Colors.black54,
                        ),
                        tooltip: _ttsService.isSpeaking ? l10n.stop : l10n.listen,
                        onPressed: () async {
                          if (_ttsService.isSpeaking) {
                            await _ttsService.stop();
                          } else {
                            await _ttsService.speak(translatedDesc);
                          }
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isLoadingRoute ? null : () => _goToLocation(location),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7C3F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isLoadingRoute
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.directions),
                      label: Text(
                        _isLoadingRoute ? l10n.tracingRoute : l10n.go,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        translatedDesc,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _ttsService.stop();
    });
  }
}