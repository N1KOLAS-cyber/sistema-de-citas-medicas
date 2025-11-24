import 'dart:ui'; // Necesario para ImageFilter (Glassmorphism)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/logger.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isDoctor = false;
  String? _selectedSpecialty;
  final TextEditingController _licenseController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog("Las contraseñas no coinciden.");
      return;
    }

    if (_isDoctor && (_selectedSpecialty == null || _licenseController.text.isEmpty)) {
      _showErrorDialog("Los doctores deben seleccionar una especialidad y proporcionar su número de licencia.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      if (userCredential.user != null) {
        Navigator.of(context).pop(); // Cerrar loading INMEDIATAMENTE
        
        // Crear documento de usuario en Firestore
        String role = _isDoctor ? 'Médico' : 'Paciente';
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDoctor: _isDoctor,
          specialty: _isDoctor ? _selectedSpecialty : null,
          licenseNumber: _isDoctor ? _licenseController.text.trim() : null,
          rating: _isDoctor ? 0.0 : null,
          totalAppointments: _isDoctor ? 0 : null,
          role: role,
        );

        // Usar FirestoreService para guardar en la colección 'usuarios'
        FirestoreService.createUser(newUser).catchError((error) {
          logInfo('⚠️ Error al guardar en Firestore (no crítico): $error');
        });

        // Mostrar mensaje de éxito y regresar al login
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("¡Registro Exitoso!"),
            content: Text(
              _isDoctor
                  ? "¡Bienvenido Dr. ${_nameController.text}!\n\nTu cuenta profesional ha sido creada. Ahora puedes iniciar sesión y gestionar tu disponibilidad."
                  : "¡Bienvenido ${_nameController.text}!\n\nTu cuenta ha sido creada. Ahora puedes iniciar sesión y agendar citas.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Regresar al login
                },
                child: const Text("Iniciar Sesión"),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      String message = "";
      if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta con este correo electrónico. Ve al login para iniciar sesión.';
      } else if (e.code == 'invalid-email') {
        message = 'Correo electrónico inválido';
      } else {
        message = e.message ?? 'Error al crear la cuenta';
      }
      _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      _showErrorDialog('Error inesperado: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          if (message.contains('Ya existe una cuenta')) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Regresar al login
              },
              child: const Text("Ir al Login"),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ],
      ),
    );
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
                      maxWidth: 450,
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
                                // Título "Register"
                                const Text(
                                  "Register",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: whiteColor,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 40),
              
              // Campo de nombre
              TextFormField(
                controller: _nameController,
                                  style: whiteTextStyle,
                                  cursorColor: whiteColor,
                                  decoration: InputDecoration(
                  labelText: "Nombre completo",
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
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
                    return "Por favor ingresa tu nombre";
                  }
                  if (value.length < 2) {
                    return "El nombre debe tener al menos 2 caracteres";
                  }
                  return null;
                },
              ),
                                const SizedBox(height: 20),

              // Campo de correo
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                                  style: whiteTextStyle,
                                  cursorColor: whiteColor,
                                  decoration: InputDecoration(
                  labelText: "Correo electrónico",
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
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
                                const SizedBox(height: 20),

              // Campo de teléfono
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                                  style: whiteTextStyle,
                                  cursorColor: whiteColor,
                                  decoration: InputDecoration(
                  labelText: "Teléfono",
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.phone_outlined,
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
                    return "Por favor ingresa tu teléfono";
                  }
                  if (value.length < 10) {
                    return "El teléfono debe tener al menos 10 dígitos";
                  }
                  return null;
                },
              ),
                                const SizedBox(height: 20),

              // Campo de contraseña
              TextFormField(
                controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: whiteTextStyle,
                                  cursorColor: whiteColor,
                                  decoration: InputDecoration(
                  labelText: "Contraseña",
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: whiteColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
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
                    return "Por favor ingresa una contraseña";
                  }
                  if (value.length < 6) {
                    return "La contraseña debe tener al menos 6 caracteres";
                  }
                  return null;
                },
              ),
                                const SizedBox(height: 20),

              // Campo de confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: whiteTextStyle,
                                  cursorColor: whiteColor,
                                  decoration: InputDecoration(
                  labelText: "Confirmar contraseña",
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: whiteColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
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
                    return "Por favor confirma tu contraseña";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Checkbox para doctor
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Checkbox(
                value: _isDoctor,
                                        activeColor: whiteColor,
                                        checkColor: Colors.black87,
                                        side: const BorderSide(
                                          color: whiteColor,
                                          width: 2,
                                        ),
                onChanged: (value) {
                  setState(() {
                    _isDoctor = value ?? false;
                    if (!_isDoctor) {
                      _selectedSpecialty = null;
                      _licenseController.clear();
                    }
                  });
                },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Soy doctor",
                                      style: TextStyle(
                                        color: whiteColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
              ),

              // Campos adicionales para doctores
              if (_isDoctor) ...[
                                  const SizedBox(height: 20),
                
                // Especialidad
                DropdownButtonFormField<String>(
                                    value: _selectedSpecialty,
                                    style: whiteTextStyle,
                                    dropdownColor: const Color(0xFF1A2744),
                                    decoration: InputDecoration(
                    labelText: "Especialidad",
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.medical_services,
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
                  items: const [
                                      DropdownMenuItem(value: "Medicina General", child: Text("Medicina General", style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: "Cardiología", child: Text("Cardiología", style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: "Dermatología", child: Text("Dermatología", style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: "Pediatría", child: Text("Pediatría", style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: "Ginecología", child: Text("Ginecología", style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: "Ortopedia", child: Text("Ortopedia", style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: "Neurología", child: Text("Neurología", style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: "Oftalmología", child: Text("Oftalmología", style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialty = value;
                    });
                  },
                  validator: (value) {
                    if (_isDoctor && (value == null || value.isEmpty)) {
                      return "Por favor selecciona una especialidad";
                    }
                    return null;
                  },
                ),
                                  const SizedBox(height: 20),

                // Número de licencia
                TextFormField(
                  controller: _licenseController,
                                    style: whiteTextStyle,
                                    cursorColor: whiteColor,
                                    decoration: InputDecoration(
                    labelText: "Número de licencia médica",
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
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
                    if (_isDoctor && (value == null || value.isEmpty)) {
                      return "Por favor ingresa tu número de licencia";
                    }
                    return null;
                  },
                ),
              ],

                                const SizedBox(height: 30),

              // Botón de registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
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
                                      "Registrarse",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

              // Botón para ir al login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                                    const Text(
                                      "¿Ya tienes cuenta? ",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Inicia sesión aquí",
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
