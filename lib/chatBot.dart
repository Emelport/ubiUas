import 'package:flutter/material.dart';
import 'dart:convert'; // Para trabajar con JSON
import 'package:http/http.dart' as http; // Para realizar solicitudes HTTP

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
  final String apiUrl = "http://127.0.0.1:5000";
  // final String apiUrl = "https://docker-api-chatbot.onrender.com";

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

  void _handleOptionSelection(String lugar) async {
    final response = await _obtenerCoordenadas(lugar);
    setState(() {
      messages.add({"bot": response});
    });
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
                  }

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue : Colors.grey[300],
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
