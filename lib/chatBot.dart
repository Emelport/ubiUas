import 'package:flutter/material.dart';
import 'dart:convert'; // Para trabajar con JSON
import 'package:http/http.dart' as http; // Para realizar solicitudes HTTP
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
      "http://127.0.0.1:5000"; // Cambiar según la URL de la API

  // Método asincrónico para iniciar la sesión
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

    if (botResponse.isNotEmpty) {
      setState(() {
        messages.add({"bot": botResponse});
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
          List<dynamic> resultados = data['resultados'];

          if (resultados.length == 1) {
            return await _obtenerCoordenadas(resultados[0][0]);
          } else {
            return {
              "opciones": resultados,
              "mensaje": "Se encontraron varios resultados. Selecciona uno:"
            };
          }
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
        return "Lugar: ${data['nombre']}\nTipo: ${data['tipo']}\nCoordenadas: ${coordenadas['latitud']}, ${coordenadas['longitud']}";
      } else {
        return 'Error al buscar el lugar.';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  // En el ChatBot, agregamos la lógica para preguntar si el usuario quiere viajar
  void _handleOptionSelection(String lugar) async {
    final response = await _obtenerCoordenadas(lugar);
    setState(() {
      messages.add({"bot": response});
    });

    // Extraemos las coordenadas del lugar para pasarlas al mapa
    RegExp coordenadasRegex =
        RegExp(r"Coordenadas:\s*(-?\d+\.\d+),\s*(-?\d+\.\d+)");
    final match = coordenadasRegex.firstMatch(response);

    if (match != null) {
      // Extraemos las coordenadas
      double latitud = double.parse(match.group(1)!);
      double longitud = double.parse(match.group(2)!);

      // Preguntar al usuario si quiere viajar a ese lugar
      setState(() {
        messages.add({
          "bot": "¿Quieres viajar a esta ubicación?",
          "coordenadas": {"latitud": latitud, "longitud": longitud}
        });
        messages.add({"bot": "Sí", "opcion": "si"});
        messages.add({"bot": "No", "opcion": "no"});
      });
    } else {
      // Si no encontramos las coordenadas, mostramos un mensaje de error
      setState(() {
        messages.add({"bot": "No se pudieron obtener las coordenadas."});
      });
    }
  }

  // Llamamos a la pantalla del mapa si el usuario responde afirmativamente.
  void _navigateToMap(BuildContext context, double lat, double lon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapScreen(lat, lon), // Pasa las coordenadas de destino
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chatbot'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message.keys.first == "user";

                  if (message['bot'] is Map) {
                    final opciones = message['bot']['opciones'];
                    final mensaje = message['bot']['mensaje'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mensaje,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...opciones.map<Widget>((opcion) {
                          return TextButton(
                            onPressed: () => _handleOptionSelection(opcion[0]),
                            child: Text(opcion[0]),
                          );
                        }).toList(),
                      ],
                    );
                  } else if (message['opcion'] == 'si' ||
                      message['opcion'] == 'no') {
                    // Mostrar solo un conjunto de botones "Sí" y "No"
                    return Column(
                      children: [
                        if (message['opcion'] == 'si')
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                final coordenadas =
                                    message['coordenadas'] as Map;
                                _navigateToMap(context, coordenadas['latitud'],
                                    coordenadas['longitud']);
                              },
                              child: const Text("Sí"),
                            ),
                          ),
                        if (message['opcion'] == 'no')
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                // Lógica para "No" (si es necesario)
                                print("PRESIONO NO");
                              },
                              child: const Text("No"),
                            ),
                          ),
                      ],
                    );
                  }

                  // Mostrar mensaje de texto normal
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message.values.first.toString(),
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
