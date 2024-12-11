import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteController {
  static final RouteController _instance = RouteController._internal();

  factory RouteController() => _instance;

  RouteController._internal();

  final ValueNotifier<List<LatLng>> routeNotifier = ValueNotifier([]);
  final ValueNotifier<LatLng?> startNotifier = ValueNotifier(null);
  final ValueNotifier<LatLng?> endNotifier = ValueNotifier(null);

  void updateRoute(LatLng start, LatLng end) {
    startNotifier.value = start;
    endNotifier.value = end;
    routeNotifier.value = [start, end];
    print(start);
    print(end);
  }
}

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Punto inicial: Facultad de Ingeniería Mochis
    pointA = const LatLng(25.814667, -108.980793);
    pointB = LatLng(widget.latitudDestino, widget.longitudDestino);

    // Obtener la ruta inicial
    if (pointA != null && pointB != null) {
      getRoute(pointA!, pointB!);
    }

    // Escuchar cambios del RouteController
    RouteController().routeNotifier.addListener(() {
      final route = RouteController().routeNotifier.value;
      if (route.isNotEmpty) {
        drawRoute(route.first, route.last);
      }
    });
  }

  /// Dibuja la ruta entre dos coordenadas.
  Future<void> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          'https://routing.openstreetmap.de/routed-foot/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=polyline');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List<dynamic> coordinates =
              _decodePolyline(data['routes'][0]['geometry']);

          setState(() {
            routePoints =
                coordinates.map((coord) => LatLng(coord[0], coord[1])).toList();
          });
        }
      } else {
        print('Error en la respuesta de la API: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener la ruta: $e');
    }
  }

  /// Decodifica la ruta en formato Polyline.
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

  /// Función para dibujar una nueva ruta entre dos puntos.
  void drawRoute(LatLng start, LatLng end) {
    setState(() {
      pointA = start;
      pointB = end;
      routePoints.clear(); // Limpia la ruta anterior
    });
    getRoute(start, end); // Obtén la nueva ruta
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Facultad Ingeniería Mochis'),
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
            polylines: [
              Polyline(
                points: routePoints,
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              if (pointA != null)
                Marker(
                  point: pointA!,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
              if (pointB != null)
                Marker(
                  point: pointB!,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
