import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa con Routing OSRM (Foot)',
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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
  }

  // Manejar la selección de puntos y solicitar la ruta
  void handleTap(LatLng latlng) {
    setState(() {
      if (pointA == null) {
        pointA = latlng;
        routePoints.clear(); // Limpiar ruta
        stepPoints.clear(); // Limpiar pasos
      } else if (pointB == null) {
        pointB = latlng;
        // Generar la ruta una vez que los puntos están seleccionados
        getRoute(pointA!, pointB!);
      } else {
        pointA = latlng;
        pointB = null;
        routePoints.clear();
        stepPoints.clear(); // Limpiar pasos
      }
    });
  }

  // Método para obtener la ruta con el perfil "foot"
  Future<void> getRoute(LatLng start, LatLng end) async {
    try {
      // Ajustar la URL para incluir el parámetro 'steps' y 'alternatives'
      final url = Uri.parse(
          'https://routing.openstreetmap.de/routed-foot/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=polyline&steps=true&alternatives=true');

      // Imprimir las coordenadas en consola
      print(start.longitude.toString());
      print(start.latitude.toString());
      print(end.longitude.toString());
      print(end.latitude.toString());

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
        });
      } else {
        print('Error en la respuesta de la API: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener la ruta: $e');
    }
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
          minZoom: 10.0,
          onTap: (tapPosition, latlng) {
            handleTap(latlng); // Manejar la selección en el mapa
          },
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
                // isDotted: true, // Opción para mostrar como línea discontinua
              ),
            ],
          ),
          MarkerLayer(
            // Marcar los puntos A y B
            markers: [
              if (pointA != null)
                Marker(
                  point: pointA!,
                  child: Icon(Icons.location_on,
                      color:
                          Colors.green), // Usar 'child' en lugar de 'builder'
                ),
              if (pointB != null)
                Marker(
                  point: pointB!,
                  child: Icon(Icons.location_on,
                      color: Colors.red), // Usar 'child' en lugar de 'builder'
                ),
            ],
          ),
        ],
      ),
    );
  }
}
