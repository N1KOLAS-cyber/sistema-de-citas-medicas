import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendPasswordReset() {
    if (!_formKey.currentState!.validate()) return;

    // Mostrar mensaje de que la funcionalidad está en desarrollo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Función en Desarrollo"),
        content: Text(
          "La funcionalidad de recuperación de contraseña estará disponible próximamente.\n\n"
          "Correo ingresado: ${_emailController.text}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Contraseña"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Icono y título
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),
              
              const Text(
                "¿Olvidaste tu contraseña?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                "Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Campo de correo electrónico
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  hintText: "ejemplo@correo.com",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
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
              const SizedBox(height: 24),
              
              // Botón de enviar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendPasswordReset,
                  icon: const Icon(Icons.send),
                  label: const Text("Enviar enlace de recuperación"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón de regresar al login
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Volver al inicio de sesión"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                ),
              ),
              const SizedBox(height: 32),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "💡 Consejos de seguridad:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("• Revisa tu bandeja de spam si no recibes el correo"),
                    Text("• El enlace de recuperación expirará en 24 horas"),
                    Text("• Nunca compartas tu contraseña con nadie"),
                    Text("• Usa una contraseña segura con al menos 6 caracteres"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

