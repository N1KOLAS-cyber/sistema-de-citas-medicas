import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del chat
              _buildChatHeader(),
              
              // Área de mensajes
              Expanded(
                child: _buildMessagesArea(),
              ),
              
              // Área de entrada (solo visual)
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Avatar del doctor
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.local_hospital,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chat Médico",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Respondemos en pocos minutos",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "En línea",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mensaje de bienvenida del doctor
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade100,
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: Colors.indigo.shade600,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: const Radius.circular(4),
                    ),
                  ),
                  child: const Text(
                    "¡Hola! 👋 Soy el asistente médico de NERV. ¿En qué puedo ayudarte hoy?",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Mensaje de ejemplo del usuario
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: const Radius.circular(4),
                    ),
                  ),
                  child: const Text(
                    "Hola, tengo una cita mañana y tengo dudas",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade600,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Respuesta del doctor
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade100,
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: Colors.indigo.shade600,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: const Radius.circular(4),
                    ),
                  ),
                  child: const Text(
                    "Perfecto, puedo ayudarte con eso. ¿Qué dudas específicas tienes sobre tu cita?",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Botones de acción (solo visuales)
          Icon(
            Icons.emoji_emotions,
            color: Colors.grey.shade500,
            size: 20,
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.attach_file,
            color: Colors.grey.shade500,
            size: 20,
          ),
          const SizedBox(width: 8),
          
          // Campo de texto (solo visual)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Escribe tu mensaje...",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón enviar (solo visual)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade600, Colors.indigo.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
