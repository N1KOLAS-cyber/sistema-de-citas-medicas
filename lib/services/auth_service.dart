// AUTH_SERVICE.DART - SERVICIO DE AUTENTICACIÓN Y PERSISTENCIA
//
// Este servicio maneja la persistencia de sesión y el estado de "Remember me"
// para mantener al usuario autenticado entre reinicios de la aplicación.
//
// FUNCIONALIDADES:
// - Guardar/recuperar sesión de usuario
// - Guardar/recuperar estado de "Remember me"
// - Guardar/recuperar email del último usuario que inició sesión
// - Limpiar datos de sesión al cerrar sesión

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keyUserId = 'saved_user_id';

  /// Guarda el estado de "Remember me" y el email del usuario
  static Future<void> saveRememberMe(bool rememberMe, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, rememberMe);
      if (rememberMe) {
        await prefs.setString(_keySavedEmail, email);
      } else {
        await prefs.remove(_keySavedEmail);
      }
    } catch (e) {
      // Si shared_preferences no está disponible (ej: web sin plugin), simplemente ignorar
      // Firebase Auth ya maneja la persistencia de sesión
    }
  }

  /// Recupera el estado de "Remember me"
  static Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Recupera el email guardado
  static Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySavedEmail);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el ID del usuario autenticado para persistencia de sesión
  static Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
    } catch (e) {
      // Si falla, simplemente ignorar (no crítico, Firebase Auth ya maneja la persistencia)
    }
  }

  /// Recupera el ID del usuario guardado
  static Future<String?> getSavedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserId);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si hay una sesión activa y devuelve el usuario
  /// Retorna null si no hay sesión o si el usuario no está autenticado
  static Future<UserModel?> getCurrentUser() async {
    try {
      // Verificar si Firebase Auth tiene un usuario autenticado
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        // Limpiar datos guardados si no hay usuario en Firebase Auth
        await clearSession();
        return null;
      }

      // Intentar obtener datos del usuario desde Firestore
      try {
        final user = await FirestoreService.getUser(firebaseUser.uid);
        if (user != null) {
          // Guardar el ID del usuario para futuras verificaciones
          await saveUserId(firebaseUser.uid);
          return user;
        }
      } catch (e) {
        // Si hay error al obtener de Firestore, retornar null
        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Limpia todos los datos de sesión guardados
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      // NO eliminamos remember_me ni saved_email para mantener la preferencia del usuario
    } catch (e) {
      // Si falla, simplemente ignorar
    }
  }

  /// Limpia completamente todos los datos (incluyendo Remember me)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keySavedEmail);
      await prefs.remove(_keyUserId);
    } catch (e) {
      // Si falla, simplemente ignorar
    }
  }
}

