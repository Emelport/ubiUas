import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Importa el paquete

class MapScreen extends StatefulWidget {
  final double latitudDestino;
  final double longitudDestino;

  const MapScreen(this.latitudDestino, this.longitudDestino, {super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  LatLng? pointA;
  LatLng? pointB;
  List<LatLng> routePoints = [];
  List<LatLng> stepPoints = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    pointB = LatLng(widget.latitudDestino, widget.longitudDestino);
  }

  // Método para obtener la ubicación actual usando Geolocator
  Future<void> _getCurrentLocation() async {
    // Verificar los permisos de ubicación
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied) {
      // Si no se tienen los permisos o el servicio está deshabilitado
      print("Ubicación no disponible.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      // Establecer las coordenadas de la ubicación actual (pointA)
      pointA = LatLng(position.latitude, position.longitude);
    });

    // Llamar a getRoute solo después de obtener la ubicación actual
    if (pointA != null && pointB != null) {
      await getRoute(pointA!, pointB!); // Obtener la ruta
    }
  }

  // Método para obtener la ruta con el perfil "foot"
  Future<void> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          'https://routing.openstreetmap.de/routed-foot/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=polyline&steps=true&alternatives=true');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Obtener la primera ruta de las alternativas
        final List<dynamic> coordinates =
            _decodePolyline(data['routes'][0]['geometry']);

        setState(() {
          routePoints = coordinates
              .map((coord) => LatLng(coord[0], coord[1]))
              .toList(); // Convertir coordenadas a LatLng

          // Si los pasos están disponibles, extraerlos (puedes personalizar esto)
          if (data['routes'][0]['legs'] != null) {
            stepPoints = _extractStepPoints(data['routes'][0]['legs'][0]);
          }
        });
      } else {
        print('Error en la respuesta de la API: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener la ruta: $e');
    }
  }

  // Método para extraer los puntos de paso de la ruta
  List<LatLng> _extractStepPoints(Map<String, dynamic> leg) {
    List<LatLng> steps = [];
    for (var step in leg['steps']) {
      var startLat = step['start_location']['lat'];
      var startLng = step['start_location']['lng'];
      steps.add(LatLng(startLat, startLng));
    }
    return steps;
  }

  // Método para decodificar la geometría en formato polyline
  List<List<double>> _decodePolyline(String encoded) {
    List<List<double>> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add([lat / 1E5, lng / 1E5]);
    }

    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa con Ruta OSRM (Foot)'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter:
              LatLng(25.814667, -108.980793), // Coordenadas iniciales
          minZoom: 8.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayer(
            // Mostrar la ruta
            polylines: [
              Polyline(
                points: routePoints,
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
              Polyline(
                points: stepPoints, // Mostrar los pasos
                color: Colors.green,
                strokeWidth: 2.0,
              ),
            ],
          ),
          MarkerLayer(
            // Marcar los puntos A y B
            markers: [
              if (pointA != null)
                Marker(
                  point: pointA!,
                  child: Icon(Icons.location_on, color: Colors.green),
                ),
              if (pointB != null)
                Marker(
                  point: pointB!,
                  child: Icon(Icons.location_on, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
