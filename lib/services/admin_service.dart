import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AdminService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear usuarios de prueba si no existen
  static Future<void> createTestUsers() async {
    await _createUser(AppConstants.adminEmail, AppConstants.adminPassword, 'Administrador', false);
    await _createUser(AppConstants.testUserEmail, AppConstants.testUserPassword, 'Usuario de Prueba', false);
  }

  // Crear un usuario específico
  static Future<void> _createUser(String email, String password, String name, bool isDoctor) async {
    try {
      // Intentar crear el usuario directamente
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Crear el documento del usuario en Firestore
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          phone: '000-000-0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDoctor: isDoctor,
        );

        try {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userModel.toMap());
          print('✅ Usuario $name creado exitosamente');
        } catch (firestoreError) {
          print('⚠️ Usuario $name creado en Auth pero error en Firestore: $firestoreError');
          // El usuario se creó en Auth, pero no en Firestore
          // Esto es aceptable para el funcionamiento básico
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('ℹ️ El usuario $name ya existe');
      } else {
        print('❌ Error de autenticación para $name: ${e.message}');
      }
    } catch (e) {
      print('❌ Error al crear usuario $name: $e');
    }
  }

  // Crear usuario administrador si no existe (método legacy)
  static Future<void> createAdminUser() async {
    await createTestUsers();
  }

  // Verificar si un usuario es administrador
  static bool isAdmin(String email) {
    return email == AppConstants.adminEmail;
  }

  // Verificar si el usuario actual es administrador
  static bool isCurrentUserAdmin() {
    final currentUser = _auth.currentUser;
    return currentUser != null && isAdmin(currentUser.email ?? '');
  }

  // Iniciar sesión como administrador
  static Future<UserCredential?> signInAsAdmin() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: AppConstants.adminEmail,
        password: AppConstants.adminPassword,
      );
      return userCredential;
    } catch (e) {
      print('❌ Error al iniciar sesión como admin: $e');
      return null;
    }
  }
}
