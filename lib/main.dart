import 'package:flutter/material.dart';
import 'package:ubiuas/mapScreen.dart'; // Reemplaza con tu implementación del mapa
import 'package:ubiuas/chatBot.dart'; // Asegúrate de que las rutas sean correctas
import 'package:geolocator/geolocator.dart'; // Importar Geolocator
import 'package:permission_handler/permission_handler.dart'; // Importar permission_handler

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa con Chatbot',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Position> _currentLocation;

  @override
  void initState() {
    super.initState();
    _currentLocation = _getCurrentLocation();
  }

  // Método para obtener la ubicación actual
  Future<Position> _getCurrentLocation() async {
    // Solicitar permisos de ubicación y cámara
    await _requestPermissions();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      throw Exception("Los servicios de ubicación están desactivados.");
    }

    // Si los permisos están denegados, solicita permisos
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Permisos de ubicación denegados.");
      }
    }

    // Si los permisos son permanentemente denegados
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permisos de ubicación permanentemente denegados.");
    }

    // Obtener la ubicación
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Método para solicitar permisos de ubicación y cámara
  Future<void> _requestPermissions() async {
    // Solicitar permisos de ubicación y cámara
    PermissionStatus locationPermission = await Permission.location.request();
    PermissionStatus cameraPermission = await Permission.camera.request();

    if (!locationPermission.isGranted) {
      throw Exception("Permiso de ubicación no concedido.");
    }

    if (!cameraPermission.isGranted) {
      throw Exception("Permiso de cámara no concedido.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa en el fondo, esperar hasta obtener la ubicación
          FutureBuilder<Position>(
            future: _currentLocation,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                Position position = snapshot.data!;
                return MapScreen(position.latitude,
                    position.longitude); // Pasar la ubicación actual
              }
              return const Center(child: Text('Ubicación no disponible.'));
            },
          ),

          // Chatbot flotante
          Positioned(
            bottom: 20, // Espaciado desde el fondo
            right: 20, // Espaciado desde el lado derecho
            child: FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => const ChatBot(),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.chat),
            ),
          ),
        ],
      ),
    );
  }
}
