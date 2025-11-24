import 'dart:ui'; // Necesario para ImageFilter (Glassmorphism)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
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
  
  // Variable para el estado visual del checkbox "Remember me"
  bool _rememberMe = false;
  // Variable para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadRememberMeState();
  }

  /// Carga el estado de "Remember me" y el email guardado
  Future<void> _loadRememberMeState() async {
    final rememberMe = await AuthService.getRememberMe();
    final savedEmail = await AuthService.getSavedEmail();
    
    setState(() {
      _rememberMe = rememberMe;
      if (savedEmail != null && rememberMe) {
        emailController.text = savedEmail;
      }
    });
  }

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
        
        // Guardar el estado de "Remember me" y el email
        final email = emailController.text.trim();
        await AuthService.saveRememberMe(_rememberMe, email);
        
        try {
          // Intentar obtener datos del usuario desde Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
          if (!mounted) return;

          if (userDoc.exists) {
            UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
            
            // Verificar si el email contiene "doctor" y el usuario no está marcado como doctor
            final email = userCredential.user!.email ?? '';
            final shouldBeDoctor = email.contains('doctor') || email.contains('medico') || email.contains('dr.');
            
            // Si el email indica que debería ser doctor pero no lo es, actualizar
            if (shouldBeDoctor && !user.isDoctor) {
              user = user.copyWith(
                isDoctor: true,
                role: 'Médico',
                updatedAt: DateTime.now(),
              );
              
              // Actualizar en Firestore
              FirestoreService.updateUser(user).catchError((error) {
                logInfo('Error al actualizar usuario a doctor: $error');
              });
            }
            
            // Guardar el ID del usuario para persistencia de sesión
            await AuthService.saveUserId(userCredential.user!.uid);
            
            // Navegar al dashboard
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(user: user),
              ),
            );
          } else {
            // Si no existe en Firestore, crear un usuario básico
            // Determinar si es doctor basado en el email
            final email = userCredential.user!.email ?? '';
            final isDoctor = email.contains('doctor') || email.contains('medico') || email.contains('dr.');
            final role = isDoctor ? 'Médico' : 'Paciente';
            final userName = userCredential.user!.displayName ?? 
                            (isDoctor ? 'Doctor' : 'Usuario');
            
            UserModel basicUser = UserModel(
              id: userCredential.user!.uid,
              email: email,
              name: userName,
              phone: 'No especificado',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isDoctor: isDoctor,
              role: role,
            );
            
            // Guardar en Firestore
            FirestoreService.createUser(basicUser).catchError((error) {
              logInfo('Error al crear usuario en Firestore: $error');
            });
            
            // Guardar el ID del usuario para persistencia de sesión
            await AuthService.saveUserId(userCredential.user!.uid);
            
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(user: basicUser),
              ),
            );
          }
        } catch (firestoreError) {
          // Si Firestore está offline, crear usuario básico
          // Determinar si es doctor basado en el email
          final email = userCredential.user!.email ?? '';
          final isDoctor = email.contains('doctor') || email.contains('medico') || email.contains('dr.');
          final role = isDoctor ? 'Médico' : 'Paciente';
          final userName = userCredential.user!.displayName ?? 
                          (isDoctor ? 'Doctor' : 'Usuario');
          
          UserModel basicUser = UserModel(
            id: userCredential.user!.uid,
            email: email,
            name: userName,
            phone: 'No especificado',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isDoctor: isDoctor,
            role: role,
          );
          
          // Guardar el ID del usuario para persistencia de sesión
          await AuthService.saveUserId(userCredential.user!.uid);
          
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

  @override
  Widget build(BuildContext context) {
    // Colores y estilos para el diseño glassmorphism (basado en referencia)
    const Color whiteColor = Colors.white;
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo con imagen (cubre toda la pantalla)
          Positioned.fill(
            child: Image.asset(
              'assets/fondo_de_login.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si no existe la imagen
                return Container(
                  color: Colors.grey[900],
                );
              },
            ),
          ),

          // 2. Contenido centrado con tarjeta glassmorphism
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 432,
                  minWidth: 320,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color.fromRGBO(26, 26, 26, 0.1), // hsla(0, 0%, 10%, .1)
                        border: Border.all(
                          color: whiteColor,
                          width: 2,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                                // Título "Login"
                                const Text(
                                  "Login",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: whiteColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Contenedor de campos
                                Column(
                                  children: [
                                    // Campo Email
                                    _buildEmailField(),
                                    const SizedBox(height: 28),
                                    
                                    // Campo Password
                                    _buildPasswordField(),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Remember Me y Forgot Password
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Checkbox Remember me
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor: whiteColor,
                                            checkColor: Colors.black87,
                                            side: const BorderSide(
                                              color: whiteColor,
                                              width: 1,
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Remember me",
                                          style: TextStyle(
                                            color: whiteColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Forgot Password Link
                                    TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: whiteColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Botón Login (blanco con texto oscuro)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: whiteColor,
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Enlace de Registro
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _navigateToRegister,
                                      child: const Text(
                                        "Register",
                                        style: TextStyle(
                                          color: whiteColor,
                                          fontWeight: FontWeight.w500,
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
            ),
          ),
        ],
      ),
    );
  }

  // Widget para campo de email con estilo de referencia
  Widget _buildEmailField() {
    const Color whiteColor = Colors.white;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 13, right: 12),
          child: Icon(
            Icons.person_outline,
            color: whiteColor,
            size: 20,
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: whiteColor,
                  width: 2,
                ),
              ),
            ),
            child: TextFormField(
              controller: emailController,
              style: const TextStyle(color: whiteColor, fontSize: 16),
              cursorColor: whiteColor,
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                floatingLabelStyle: TextStyle(
                  color: whiteColor,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 13, bottom: 13),
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
          ),
        ),
      ],
    );
  }

  // Widget para campo de contraseña con estilo de referencia
  Widget _buildPasswordField() {
    const Color whiteColor = Colors.white;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 13, right: 12),
          child: Icon(
            Icons.lock_outline,
            color: whiteColor,
            size: 20,
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: whiteColor,
                  width: 2,
                ),
              ),
            ),
            child: TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: whiteColor, fontSize: 16),
              cursorColor: whiteColor,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                floatingLabelStyle: const TextStyle(
                  color: whiteColor,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(
                  top: 13,
                  bottom: 13,
                  right: 30,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: whiteColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Por favor ingresa tu contraseña";
                }
                if (value.length < 6) {
                  return "Mínimo 6 caracteres";
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
