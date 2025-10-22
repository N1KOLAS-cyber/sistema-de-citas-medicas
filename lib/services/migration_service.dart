import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para migrar datos de colecciones antiguas a las nuevas
class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migra todos los usuarios de 'users' a 'usuarios'
  /// Retorna el número de usuarios migrados
  static Future<int> migrateUsersToUsuarios() async {
    try {
      print('🔄 Iniciando migración de users a usuarios...');
      
      // Obtener todos los documentos de 'users'
      QuerySnapshot oldUsers = await _firestore
          .collection('users')
          .get();
      
      if (oldUsers.docs.isEmpty) {
        print('ℹ️ No hay usuarios en la colección "users" para migrar');
        return 0;
      }

      print('📊 Encontrados ${oldUsers.docs.length} usuarios para migrar');
      
      // Copiar a 'usuarios' usando batch
      WriteBatch batch = _firestore.batch();
      int count = 0;
      
      for (var doc in oldUsers.docs) {
        try {
          var data = doc.data() as Map<String, dynamic>;
          
          // Verificar si el usuario ya existe en 'usuarios'
          DocumentSnapshot existingUser = await _firestore
              .collection('usuarios')
              .doc(doc.id)
              .get();
          
          if (!existingUser.exists) {
            batch.set(
              _firestore.collection('usuarios').doc(doc.id),
              data,
            );
            count++;
          } else {
            print('⚠️ Usuario ${doc.id} ya existe en "usuarios", saltando...');
          }
        } catch (e) {
          print('❌ Error al migrar usuario ${doc.id}: $e');
        }
      }
      
      if (count > 0) {
        await batch.commit();
        print('✅ Migración completada: $count usuarios migrados');
      } else {
        print('ℹ️ No hay nuevos usuarios para migrar');
      }
      
      return count;
    } catch (e) {
      print('❌ Error en migración: $e');
      return 0;
    }
  }

  /// Migra todos los appointments de 'appointments' a 'citas'
  static Future<int> migrateAppointmentsToCitas() async {
    try {
      print('🔄 Iniciando migración de appointments a citas...');
      
      QuerySnapshot oldAppointments = await _firestore
          .collection('appointments')
          .get();
      
      if (oldAppointments.docs.isEmpty) {
        print('ℹ️ No hay citas en la colección "appointments" para migrar');
        return 0;
      }

      print('📊 Encontradas ${oldAppointments.docs.length} citas para migrar');
      
      WriteBatch batch = _firestore.batch();
      int count = 0;
      
      for (var doc in oldAppointments.docs) {
        try {
          var data = doc.data() as Map<String, dynamic>;
          
          DocumentSnapshot existingAppointment = await _firestore
              .collection('citas')
              .doc(doc.id)
              .get();
          
          if (!existingAppointment.exists) {
            batch.set(
              _firestore.collection('citas').doc(doc.id),
              data,
            );
            count++;
          }
        } catch (e) {
          print('❌ Error al migrar cita ${doc.id}: $e');
        }
      }
      
      if (count > 0) {
        await batch.commit();
        print('✅ Migración completada: $count citas migradas');
      }
      
      return count;
    } catch (e) {
      print('❌ Error en migración: $e');
      return 0;
    }
  }

  /// Realiza todas las migraciones necesarias
  static Future<Map<String, int>> migrateAll() async {
    int usersMigrated = await migrateUsersToUsuarios();
    int appointmentsMigrated = await migrateAppointmentsToCitas();
    
    return {
      'usuarios': usersMigrated,
      'citas': appointmentsMigrated,
    };
  }

  /// Verifica si existen datos en las colecciones antiguas
  static Future<bool> needsMigration() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .limit(1)
          .get();
      
      QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('appointments')
          .limit(1)
          .get();
      
      return usersSnapshot.docs.isNotEmpty || 
             appointmentsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al verificar migración: $e');
      return false;
    }
  }

  /// Crea un respaldo de las colecciones nuevas antes de migrar
  static Future<void> createBackup() async {
    try {
      print('💾 Creando respaldo...');
      
      // Respaldar usuarios
      QuerySnapshot usuarios = await _firestore
          .collection('usuarios')
          .get();
      
      if (usuarios.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        
        for (var doc in usuarios.docs) {
          batch.set(
            _firestore.collection('usuarios_backup').doc(doc.id),
            doc.data() as Map<String, dynamic>,
          );
        }
        
        await batch.commit();
        print('✅ Respaldo de usuarios completado');
      }
    } catch (e) {
      print('❌ Error al crear respaldo: $e');
    }
  }

  /// Obtiene estadísticas de las colecciones
  static Future<Map<String, dynamic>> getCollectionStats() async {
    try {
      // Usuarios
      QuerySnapshot usersOld = await _firestore.collection('users').get();
      QuerySnapshot usersNew = await _firestore.collection('usuarios').get();
      
      // Citas
      QuerySnapshot appointmentsOld = await _firestore.collection('appointments').get();
      QuerySnapshot appointmentsNew = await _firestore.collection('citas').get();
      
      // Disponibilidad
      QuerySnapshot availability = await _firestore.collection('disponibilidad_medicos').get();
      
      return {
        'users_old': usersOld.docs.length,
        'usuarios_new': usersNew.docs.length,
        'appointments_old': appointmentsOld.docs.length,
        'citas_new': appointmentsNew.docs.length,
        'disponibilidad_medicos': availability.docs.length,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {};
    }
  }
}

