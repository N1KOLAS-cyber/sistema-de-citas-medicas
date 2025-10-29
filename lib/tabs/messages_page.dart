import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
              
              // Área de entrada funcional
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
    return StreamBuilder<QuerySnapshot>(
      stream: _getMessagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildWelcomeMessage();
        }

        List<QueryDocumentSnapshot> messages = snapshot.data!.docs;
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final data = message.data() as Map<String, dynamic>;
            final isFromUser = data['senderId'] == _auth.currentUser?.uid;
            
            return _buildMessageBubble(
              message: data['message'] ?? '',
              isFromUser: isFromUser,
              timestamp: data['timestamp'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
                  : DateTime.now(),
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeMessage() {
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
                    "¡Hola! 👋 Soy el asistente médico de MedCitas. ¿En qué puedo ayudarte hoy?",
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

  Widget _buildMessageBubble({
    required String message,
    required bool isFromUser,
    required DateTime timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromUser) ...[
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
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isFromUser ? Colors.indigo.shade600 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isFromUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomRight: isFromUser ? const Radius.circular(16) : const Radius.circular(4),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isFromUser ? Colors.white : Colors.black87,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (isFromUser) ...[
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
          // Botones de acción
          GestureDetector(
            onTap: () {
              // TODO: Implementar emojis
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Emojis próximamente")),
              );
            },
            child: Icon(
              Icons.emoji_emotions,
              color: Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // TODO: Implementar adjuntos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Adjuntos próximamente")),
              );
            },
            child: Icon(
              Icons.attach_file,
              color: Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          
          // Campo de texto funcional
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Escribe tu mensaje...",
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _sendMessage(value.trim());
                }
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón enviar funcional
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                _sendMessage(_messageController.text.trim());
              }
            },
            child: Container(
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
          ),
        ],
      ),
    );
  }

  /**
   * Obtiene el stream de mensajes desde Firestore
   * @return Stream<QuerySnapshot> - Stream de mensajes
   */
  Stream<QuerySnapshot> _getMessagesStream() {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /**
   * Envía un mensaje al chat
   * @param message - Contenido del mensaje
   */
  void _sendMessage(String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes iniciar sesión para enviar mensajes"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Limpiar el campo de texto
      _messageController.clear();

      // Guardar mensaje en Firestore
      await _firestore.collection('messages').add({
        'message': message,
        'senderId': user.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Scroll hacia abajo para mostrar el nuevo mensaje
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al enviar mensaje: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
