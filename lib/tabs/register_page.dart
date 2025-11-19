import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

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
          print('⚠️ Error al guardar en Firestore (no crítico): $error');
        });

        // Mostrar mensaje de éxito y regresar al login
        if (mounted) {
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
      }
    } on FirebaseAuthException catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro"),
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
              
              // Campo de nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre completo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
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
              const SizedBox(height: 16),

              // Campo de correo
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
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
              const SizedBox(height: 16),

              // Campo de teléfono
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
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
              const SizedBox(height: 16),

              // Campo de contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
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
              const SizedBox(height: 16),

              // Campo de confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirmar contraseña",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
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
              CheckboxListTile(
                title: const Text("Soy doctor"),
                subtitle: const Text("Marcar si eres un profesional médico"),
                value: _isDoctor,
                onChanged: (value) {
                  setState(() {
                    _isDoctor = value ?? false;
                    if (!_isDoctor) {
                      _selectedSpecialty = null;
                      _licenseController.clear();
                    }
                  });
                },
                activeColor: Colors.indigo,
              ),

              // Campos adicionales para doctores
              if (_isDoctor) ...[
                const SizedBox(height: 16),
                
                // Especialidad
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: const InputDecoration(
                    labelText: "Especialidad",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Medicina General", child: Text("Medicina General")),
                    DropdownMenuItem(value: "Cardiología", child: Text("Cardiología")),
                    DropdownMenuItem(value: "Dermatología", child: Text("Dermatología")),
                    DropdownMenuItem(value: "Pediatría", child: Text("Pediatría")),
                    DropdownMenuItem(value: "Ginecología", child: Text("Ginecología")),
                    DropdownMenuItem(value: "Ortopedia", child: Text("Ortopedia")),
                    DropdownMenuItem(value: "Neurología", child: Text("Neurología")),
                    DropdownMenuItem(value: "Oftalmología", child: Text("Oftalmología")),
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
                const SizedBox(height: 16),

                // Número de licencia
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: "Número de licencia médica",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (_isDoctor && (value == null || value.isEmpty)) {
                      return "Por favor ingresa tu número de licencia";
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Botón de registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Registrarse", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              // Botón para ir al login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Ya tienes cuenta? "),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Inicia sesión aquí",
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
