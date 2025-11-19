import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- FUNCIÓN DE LOGIN ---
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
        Navigator.of(context).pop(); // Cerrar loading
        
        try {
          // Intentar obtener datos del usuario desde Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
          if (!mounted) return;

          if (userDoc.exists) {
            UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
            
            // Navegar al dashboard
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(user: user),
              ),
            );
          } else {
            // Si no existe en Firestore, crear un usuario básico
            UserModel basicUser = UserModel(
              id: userCredential.user!.uid,
              email: userCredential.user!.email ?? '',
              name: userCredential.user!.displayName ?? 'Usuario',
              phone: 'No especificado',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isDoctor: false,
              role: 'Paciente',
            );
            
            // Guardar en Firestore
            FirestoreService.createUser(basicUser).catchError((error) {
              logInfo('⚠️ Error al crear usuario en Firestore: $error');
            });
            
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(user: basicUser),
              ),
            );
          }
        } catch (firestoreError) {
          // Si Firestore está offline, crear usuario básico
          UserModel basicUser = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'Usuario',
            phone: 'No especificado',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isDoctor: false,
            role: 'Paciente',
          );
          
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(user: basicUser),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      String message = "";
      if (e.code == 'user-not-found') {
        message = 'Correo o contraseña inválidos';
      } else if (e.code == 'wrong-password') {
        message = 'Correo o contraseña inválidos';
      } else if (e.code == 'invalid-email') {
        message = 'Correo o contraseña inválidos';
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
  
  // --- FUNCIÓN PARA OLVIDÉ MI CONTRASEÑA ---
  Future<void> _forgotPassword() async {
    if (emailController.text.isEmpty) {
      _showErrorDialog("Por favor ingresa tu correo electrónico para recuperar la contraseña.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
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
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('Error inesperado: $e');
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  // Función para login rápido como administrador
  Future<void> _loginAsAdmin() async {
    emailController.text = AppConstants.adminEmail;
    passwordController.text = AppConstants.adminPassword;
    await _login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Demo"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
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
                onPressed: _forgotPassword,
                child: const Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
              const SizedBox(height: 20),
              // --- BOTÓN DE ACCESO RÁPIDO ADMIN ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loginAsAdmin,
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text("Acceso Rápido Admin"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}