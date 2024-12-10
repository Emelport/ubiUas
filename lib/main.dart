import 'package:flutter/material.dart';
import 'package:ubiuas/mapScreen.dart'; // Reemplaza con tu implementación del mapa
import 'package:ubiuas/chatBot.dart'; // Asegúrate de que las rutas sean correctas

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa en el fondo
          const MapScreen(), // Implementa tu mapa aquí

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
