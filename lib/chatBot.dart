import 'package:flutter/material.dart';

class ChatBot extends StatelessWidget {
  const ChatBot({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chatbot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Bienvenido al chatbot. ¿En qué puedo ayudarte?'),
        ],
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
