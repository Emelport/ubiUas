import 'package:flutter/material.dart';
import 'dart:convert'; // Para trabajar con JSON
import 'package:http/http.dart' as http; // Para realizar solicitudes HTTP
import 'package:latlong2/latlong.dart';
import 'package:ubiuas/mapScreen.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  _ChatBotState createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final List<Map<String, dynamic>> messages = []; // Mensajes dinámicos
  final TextEditingController _controller = TextEditingController();
  final String sessionId =
      "usuario_123"; // ID de sesión fijo para esta implementación
  final String apiUrl =
      "https://docker-api-chatbot.onrender.com/"; // Cambiar según la URL de la API

  Future<String> iniciarSesion() async {
    try {
      final url = Uri.parse(apiUrl + '/iniciar');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "session_id": sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return 'Sesión iniciada con éxito';
      } else {
        return 'Error al iniciar la sesión: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error al iniciar la sesión: $e';
    }
  }

  @override
  void initState() {
    super.initState();
    iniciarSesion().then((result) {
      print(result); // Mostrar el resultado de la sesión
    });
  }

  void sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      messages.add({"user": text});
    });

    final botResponse = await _getBotResponse(text);

    if (botResponse != null) {
      setState(() {
        if (botResponse is Map && botResponse['opciones'] != null) {
          messages.add({"bot_opciones": botResponse});
        } else {
          messages.add({"bot": botResponse});
        }
      });
    }
    _controller.clear();
  }

  Future<dynamic> _getBotResponse(String userMessage) async {
    if (userMessage.toLowerCase().contains('hola')) {
      return '¡Hola! ¿Cómo puedo ayudarte?';
    } else if (userMessage.toLowerCase().contains('adios')) {
      return '¡Adiós! Que tengas un buen día.';
    } else {
      return await _consultarAPI(userMessage);
    }
  }

  Future<dynamic> _consultarAPI(String mensaje) async {
    try {
      final url = Uri.parse(apiUrl + '/mensaje');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "session_id": sessionId,
          "mensaje": mensaje,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['resultados'] != null) {
          return {
            "opciones": data['resultados'],
            "mensaje": "Se encontraron varios resultados. Selecciona uno:"
          };
        } else {
          return 'No se encontraron resultados.';
        }
      } else {
        return 'Error al consultar la API.';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _obtenerCoordenadas(String lugar) async {
    try {
      final url = Uri.parse(apiUrl + '/buscar_lugar');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"nombre": lugar, "session_id": sessionId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coordenadas = data['coordenadas'];
        final latitud = coordenadas['latitud'];
        final longitud = coordenadas['longitud'];

        setState(() {
          messages.add({
            "bot":
                "Lugar: ${data['nombre']}\nTipo: ${data['tipo']}\nCoordenadas: $latitud, $longitud",
          });
          messages.add({
            "bot": "¿Quieres viajar a esta ubicación?",
            "coordenadas": {"latitud": latitud, "longitud": longitud}
          });
        });
        return "Preguntando...";
      } else {
        return 'Error al buscar el lugar.';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  void _navigateToMap(BuildContext context, double? lat, double? lon) {
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pueden cargar las coordenadas.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(lat, lon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UbiUAS Chatbot Interactivo',
            style: TextStyle(fontSize: 20)),
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message.keys.first == "user";

                    if (message.containsKey('bot_opciones')) {
                      final opciones = message['bot_opciones']['opciones'];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['bot_opciones']['mensaje'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ...opciones.map<Widget>((opcion) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 212, 229, 236),
                                textStyle: const TextStyle(fontSize: 14),
                              ),
                              onPressed: () {
                                _obtenerCoordenadas(opcion[0]);
                              },
                              child: Text(opcion[0]),
                            );
                          }).toList(),
                        ],
                      );
                    }

                    if (message.containsKey('coordenadas')) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              final coords = message['coordenadas'];
                              _navigateToMap(context, coords['latitud'],
                                  coords['longitud']);
                            },
                            child: const Text("Sí",
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                messages.add({"bot": "¡Entendido!"});
                              });
                            },
                            child: const Text("No",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    }

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message.values.first.toString(),
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () => sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
