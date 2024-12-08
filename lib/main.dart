import 'package:flutter/material.dart';
import 'package:ubiuas/mapScreen.dart';
import 'package:ubiuas/chatBot.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa con Routing OSRM (Foot)',
      home: HomeScreen(),
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
          const MapScreen(),

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
