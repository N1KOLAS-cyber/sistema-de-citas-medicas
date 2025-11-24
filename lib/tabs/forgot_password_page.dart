import 'dart:ui'; // Necesario para ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text("Correo Enviado"),
          content: const Text("Se ha enviado un enlace de recuperación a tu correo electrónico."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
    } on FirebaseAuthException catch (e) {
      String message = "";
      if (e.code == 'user-not-found') {
        message = 'No existe una cuenta con este correo electrónico';
      } else if (e.code == 'invalid-email') {
        message = 'Correo electrónico inválido';
      } else {
        message = e.message ?? 'Error al enviar el correo de recuperación';
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text('Error inesperado: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores y estilos para el diseño glassmorphism
    const Color whiteColor = Colors.white;
    const TextStyle whiteTextStyle = TextStyle(color: whiteColor);
    final Color inputFillColor = Colors.white.withOpacity(0.15);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo tecnológico/médico
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1628), // Azul muy oscuro
                  Color(0xFF1A2744), // Azul oscuro
                  Color(0xFF2A3A5C), // Azul medio oscuro
                ],
              ),
            ),
          ),
          
          // 2. Patrón de cuadrados y hexágonos decorativos
          CustomPaint(
            painter: MedicalTechBackgroundPainter(),
            size: Size.infinite,
          ),

          // 3. Contenido centrado con tarjeta glassmorphism
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tarjeta con efecto Glassmorphism
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      minWidth: 320,
      ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 40,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
        child: Form(
          key: _formKey,
          child: Column(
                              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono y título
              const Icon(
                Icons.lock_reset,
                                  size: 60,
                                  color: whiteColor,
              ),
              const SizedBox(height: 24),
              
              const Text(
                                  "Forgot Password?",
                textAlign: TextAlign.center,
                style: TextStyle(
                                    color: whiteColor,
                                    fontSize: 32,
                  fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                                  "Enter your email and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                ),
              ),
                                const SizedBox(height: 40),
              
              // Campo de correo electrónico
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                                  style: whiteTextStyle,
                                  cursorColor: whiteColor,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                  hintText: "ejemplo@correo.com",
                                    hintStyle: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: whiteColor,
                                    ),
                                    filled: true,
                                    fillColor: inputFillColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: whiteColor,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa tu correo";
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return "Correo no válido";
                  }
                  return null;
                },
              ),
                                const SizedBox(height: 30),
              
              // Botón de enviar
              SizedBox(
                width: double.infinity,
                                  child: ElevatedButton(
                  onPressed: _sendPasswordReset,
                  style: ElevatedButton.styleFrom(
                                      backgroundColor: whiteColor,
                                      foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Send Reset Link",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
                                const SizedBox(height: 20),
              
              // Botón de regresar al login
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Remember your password? ",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: const Text(
                                        "Login",
                      style: TextStyle(
                                          color: whiteColor,
                        fontWeight: FontWeight.bold,
                                          fontSize: 13,
                      ),
                    ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter para el fondo tecnológico/médico (reutilizado)
class MedicalTechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dibujar cuadrados pequeños en la parte superior derecha
    for (int i = 0; i < 30; i++) {
      final x = size.width * 0.6 + (i % 10) * 40.0;
      final y = size.height * 0.1 + (i ~/ 10) * 40.0;
      final rect = Rect.fromLTWH(x, y, 20, 20);
      canvas.drawRect(rect, strokePaint);
    }

    // Dibujar grid en la parte inferior
    final gridPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, size.height * 0.7),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (double y = size.height * 0.7; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

