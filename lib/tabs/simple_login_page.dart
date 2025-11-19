//
// SIMPLE LOGIN PAGE - PÁGINA DE INICIO DE SESIÓN
//
// Este archivo contiene la página de login principal del sistema.
// Permite autenticación con email/contraseña y acceso rápido para testing.
//
// FUNCIONALIDADES:
// - Login con email y contraseña
// - Login anónimo para usuarios invitados
// - Acceso rápido para admin y usuario de prueba
// - Navegación a registro y recuperación de contraseña
// - Validación de formularios
// - Manejo de errores de autenticación
//
// ESTRUCTURA:
// - Formulario de login con validación
// - Botones de acceso rápido (Admin, Usuario, Invitado)
// - Navegación a otras páginas
// - Logo y branding de la aplicación
//
// VISUALIZACIÓN: Página de login con diseño moderno, logo de la app,
// formulario centrado y botones de acceso rápido para facilitar testing.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import '../services/firestore_service.dart';
import '../utils/logger.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class SimpleLoginPage extends StatefulWidget {
  const SimpleLoginPage({super.key});

  @override
  State<SimpleLoginPage> createState() => _SimpleLoginPageState();
}

class _SimpleLoginPageState extends State<SimpleLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  ///
  /// Función principal de login con email y contraseña
  /// Maneja autenticación, carga de datos de usuario y navegación
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;

      if (userCredential.user != null) {
        // Intentar cargar datos del usuario desde Firestore
        UserModel? user;
        
        try {
          user = await FirestoreService.getUser(userCredential.user!.uid);
          if (!mounted) return;
          logInfo('✅ Usuario cargado de Firestore: ${user?.name}, role: ${user?.role}, isDoctor: ${user?.isDoctor}');
        } catch (e) {
          logInfo('⚠️ Error al cargar datos de Firestore: $e');
        }
        
          // Si no hay datos en Firestore, crear usuario básico
        if (user == null) {
          String userName = 'Usuario';
          bool isDoctor = false;
          String? role;
          
          // Determinar el nombre y tipo de usuario basado en el email
          if (emailController.text.contains('admin') || emailController.text.contains('doctor')) {
            userName = 'Administrador';
            role = 'Médico';
            isDoctor = true;
          } else if (emailController.text.contains('test')) {
            userName = 'Usuario de Prueba';
            role = 'Paciente';
          } else if (emailController.text.contains('anonimo')) {
            userName = 'Usuario Anónimo';
            role = 'Paciente';
          } else {
            // Para usuarios registrados, usar el email como base para el nombre
            String emailPrefix = emailController.text.split('@')[0];
            userName = emailPrefix.isNotEmpty ? emailPrefix : 'Usuario';
            // Por defecto es Paciente
            role = 'Paciente';
          }
          
          user = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userName,
            phone: 'No especificado',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isDoctor: isDoctor,
            role: role,
          );
          
          // Intentar crear el documento en Firestore en segundo plano
          FirestoreService.createUser(user).catchError((error) {
            logInfo('⚠️ Error al crear usuario en Firestore: $error');
          });
          
          logInfo('✅ Usuario nuevo creado: ${user.name}, role: ${user.role}, isDoctor: ${user.isDoctor}');
        } else {
          // Usuario existe, verificar que tenga rol
          if (user.role == null && user.isDoctor) {
            // Actualizar rol si falta pero isDoctor es true
            user = user.copyWith(role: 'Médico');
            FirestoreService.updateUser(user).catchError((error) {
              logInfo('⚠️ Error al actualizar rol: $error');
            });
          }
        }
        
        Navigator.of(context).pop(); // Cerrar loading
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(user: user!),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      String message = "";
      if (e.code == 'user-not-found') {
        message = 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        message = 'Correo electrónico inválido';
      } else if (e.code == 'user-disabled') {
        message = 'Usuario deshabilitado';
      } else {
        message = e.message ?? 'Error al iniciar sesión';
      }
      _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      _showErrorDialog('Error inesperado: $e');
    }
  }

  ///
  /// Muestra un diálogo de error con el mensaje especificado
  /// @param message - Mensaje de error a mostrar
  void _showErrorDialog(String message) {
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
  }

  ///
  /// Login rápido como administrador usando credenciales predefinidas
  /// Facilita el testing y desarrollo
  Future<void> _loginAsAdmin() async {
    emailController.text = AppConstants.adminEmail;
    passwordController.text = AppConstants.adminPassword;
    await _login();
  }

  ///
  /// Login rápido como usuario de prueba usando credenciales predefinidas
  /// Facilita el testing con un usuario normal
  Future<void> _loginAsTestUser() async {
    emailController.text = AppConstants.testUserEmail;
    passwordController.text = AppConstants.testUserPassword;
    await _login();
  }

  ///
  /// Login anónimo para usuarios invitados
  /// Permite acceso sin registro para explorar la aplicación
  Future<void> _loginAnonymously() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      if (!mounted) return;
      
      if (userCredential.user != null) {
        // Crear usuario anónimo básico
        UserModel anonymousUser = UserModel(
          id: userCredential.user!.uid,
          email: 'usuario.anonimo@temp.com',
          name: 'Usuario Anónimo',
          phone: 'No especificado',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDoctor: false,
        );
        
        if (!mounted) return;
        Navigator.of(context).pop(); // Cerrar loading
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(user: anonymousUser),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      _showErrorDialog('Error al iniciar sesión anónima: $e');
    }
  }

  ///
  /// Navega a la página de registro
  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // --- LOGO ---
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.local_hospital,
                        size: 80,
                        color: Colors.indigo,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- NOMBRE DE LA APP ---
              const Text(
                "MedCitas",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sistema de Citas Médicas",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              // --- CAMPO DE CORREO ---
              TextFormField(
                controller: emailController,
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
              // --- CAMPO DE CONTRASEÑA ---
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa tu contraseña";
                  }
                  if (value.length < 6) {
                    return "La contraseña debe tener al menos 6 caracteres";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // --- BOTÓN DE INICIAR SESIÓN ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Iniciar sesión", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              // --- BOTÓN DE OLVIDÉ MI CONTRASEÑA ---
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
              const SizedBox(height: 4),
              // --- BOTÓN DE REGISTRO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes cuenta? "),
                  TextButton(
                    onPressed: _navigateToRegister,
                    child: const Text(
                      "Regístrate aquí",
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- BOTONES DE ACCESO RÁPIDO EN EL LADO DERECHO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // --- BOTÓN DE LOGIN ANÓNIMO ---
                  OutlinedButton.icon(
                    onPressed: _loginAnonymously,
                    icon: const Icon(Icons.visibility_off, size: 14),
                    label: const Text("Invitado", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // --- BOTÓN DE ACCESO RÁPIDO USUARIO ---
                  OutlinedButton.icon(
                    onPressed: _loginAsTestUser,
                    icon: const Icon(Icons.person, size: 14),
                    label: const Text("Usuario", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // --- BOTÓN DE ACCESO RÁPIDO ADMIN ---
                  OutlinedButton.icon(
                    onPressed: _loginAsAdmin,
                    icon: const Icon(Icons.admin_panel_settings, size: 14),
                    label: const Text("Admin", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(0, 32),
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
