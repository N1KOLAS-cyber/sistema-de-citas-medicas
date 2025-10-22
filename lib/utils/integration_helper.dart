import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/migration_service.dart';
import '../models/user_model.dart';

/// Helper para verificar y testear la integración
class IntegrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifica el estado de la integración
  static Future<Map<String, dynamic>> checkIntegrationStatus() async {
    try {
      print('🔍 Verificando estado de la integración...\n');

      // 1. Verificar colecciones
      Map<String, dynamic> stats = await MigrationService.getCollectionStats();
      
      print('📊 Estadísticas de Colecciones:');
      print('   users (antigua): ${stats['users_old']} documentos');
      print('   usuarios (nueva): ${stats['usuarios_new']} documentos ✅');
      print('   appointments (antigua): ${stats['appointments_old']} documentos');
      print('   citas (nueva): ${stats['citas_new']} documentos ✅');
      print('   disponibilidad_medicos: ${stats['disponibilidad_medicos']} documentos ✅\n');

      // 2. Verificar usuario actual
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('👤 Usuario Actual:');
        print('   UID: ${currentUser.uid}');
        print('   Email: ${currentUser.email}\n');

        // Intentar cargar datos del usuario
        UserModel? userData = await FirestoreService.getUser(currentUser.uid);
        if (userData != null) {
          print('✅ Datos del usuario cargados desde Firestore');
          print('   Nombre: ${userData.name}');
          print('   Es Doctor: ${userData.isDoctor}');
          if (userData.isDoctor) {
            print('   Especialidad: ${userData.specialty}');
          }
          if (userData.medicalHistory != null && userData.medicalHistory!.isNotEmpty) {
            print('   Historial Médico: ${userData.medicalHistory}');
          }
        } else {
          print('⚠️ No se encontraron datos en Firestore para este usuario');
        }
      } else {
        print('ℹ️ No hay usuario autenticado actualmente\n');
      }

      // 3. Verificar si necesita migración
      bool needsMigration = await MigrationService.needsMigration();
      if (needsMigration) {
        print('⚠️ HAY DATOS EN COLECCIONES ANTIGUAS QUE PUEDEN MIGRARSE\n');
      } else {
        print('✅ No hay datos pendientes de migración\n');
      }

      return {
        'success': true,
        'stats': stats,
        'currentUser': currentUser?.uid,
        'needsMigration': needsMigration,
      };
    } catch (e) {
      print('❌ Error al verificar integración: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Crea datos de prueba para testing
  static Future<void> createTestData() async {
    try {
      print(' Creando datos de prueba...\n');

      // Crear un doctor de prueba
      String doctorId = 'test_doctor_${DateTime.now().millisecondsSinceEpoch}';
      UserModel testDoctor = UserModel(
        id: doctorId,
        email: 'doctor.prueba@test.com',
        name: 'Dr. Carlos Ruiz',
        phone: '+34 600 123 456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDoctor: true,
        specialty: 'Cardiología',
        licenseNumber: 'MED-12345',
        rating: 4.5,
        totalAppointments: 0,
      );

      await FirestoreService.createUser(testDoctor);
      print('✅ Doctor de prueba creado: ${testDoctor.name}');

      // Crear horarios disponibles para el doctor (próximos 3 días)
      for (int day = 1; day <= 3; day++) {
        DateTime date = DateTime.now().add(Duration(days: day));
        
        List<Map<String, DateTime>> timeSlots = [];
        for (int hour = 9; hour < 17; hour++) {
          DateTime start = DateTime(date.year, date.month, date.day, hour, 0);
          DateTime end = start.add(const Duration(hours: 1));
          timeSlots.add({'start': start, 'end': end});
        }

        await FirestoreService.createBulkAvailability(
          doctorId,
          testDoctor.name,
          date,
          timeSlots,
        );
      }
      print(' Horarios creados para los próximos 3 días\n');

      // Crear un paciente de prueba
      String patientId = 'test_patient_${DateTime.now().millisecondsSinceEpoch}';
      UserModel testPatient = UserModel(
        id: patientId,
        email: 'paciente.prueba@test.com',
        name: 'Ana García',
        phone: '+34 600 654 321',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDoctor: false,
        medicalHistory: 'Alergia a la penicilina, hipertensión controlada',
      );

      await FirestoreService.createUser(testPatient);
      print(' Paciente de prueba creado: ${testPatient.name}');
      print('   Historial médico incluido\n');

      print(' ¡Datos de prueba creados exitosamente!\n');
      print(' Credenciales de prueba:');
      print('   Doctor: doctor.prueba@test.com');
      print('   Paciente: paciente.prueba@test.com');
      print('   (Nota: Estos usuarios no tienen contraseña de Auth, solo datos en Firestore)\n');

    } catch (e) {
      print('❌ Error al crear datos de prueba: $e');
    }
  }

  /// Muestra un diálogo con el estado de la integración
  static Future<void> showIntegrationDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic> status = await checkIntegrationStatus();
    
    if (!context.mounted) return;
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status['success'] ? Icons.check_circle : Icons.error,
              color: status['success'] ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Estado de Integración'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status['success']) ...[
                Text('Usuarios: ${status['stats']['usuarios_new']} documentos'),
                Text('Citas: ${status['stats']['citas_new']} documentos'),
                Text('Horarios: ${status['stats']['disponibilidad_medicos']} documentos'),
                const SizedBox(height: 16),
                if (status['needsMigration'] == true) ...[
                  const Text(
                    '⚠️ Hay datos en colecciones antiguas',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _runMigration(context);
                    },
                    child: const Text('Migrar Datos'),
                  ),
                ] else ...[
                  const Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Todo listo para usar'),
                    ],
                  ),
                ],
              ] else ...[
                Text('Error: ${status['error']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static Future<void> _runMigration(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Migrando datos...'),
          ],
        ),
      ),
    );

    Map<String, int> results = await MigrationService.migrateAll();
    
    if (!context.mounted) return;
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migración Completada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuarios migrados: ${results['usuarios']}'),
            Text('Citas migradas: ${results['citas']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Limpia datos de prueba
  static Future<void> cleanTestData() async {
    try {
      print('🧹 Limpiando datos de prueba...\n');

      // Buscar y eliminar usuarios de prueba
      QuerySnapshot testUsers = await _firestore
          .collection('usuarios')
          .where('email', whereIn: ['doctor.prueba@test.com', 'paciente.prueba@test.com'])
          .get();

      for (var doc in testUsers.docs) {
        await doc.reference.delete();
        print('🗑️ Usuario eliminado: ${doc.id}');
      }

      print('\n✅ Datos de prueba eliminados\n');
    } catch (e) {
      print('❌ Error al limpiar datos: $e');
    }
  }

  /// Verifica la configuración de las reglas de Firestore
  static Future<bool> checkFirestoreRules() async {
    try {
      print('🔒 Verificando reglas de Firestore...\n');

      User? user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No hay usuario autenticado para verificar las reglas');
        return false;
      }

      // Intentar leer la colección usuarios
      try {
        await _firestore.collection('usuarios').doc(user.uid).get();
        print('✅ Reglas de lectura configuradas correctamente');
      } catch (e) {
        print('❌ Error al leer usuarios: $e');
        print('   Posiblemente las reglas no están configuradas');
        return false;
      }

      // Intentar escribir
      try {
        await _firestore.collection('usuarios').doc(user.uid).update({
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('✅ Reglas de escritura configuradas correctamente\n');
        return true;
      } catch (e) {
        print('❌ Error al escribir usuarios: $e');
        print('   Posiblemente las reglas no están configuradas\n');
        return false;
      }
    } catch (e) {
      print('❌ Error al verificar reglas: $e\n');
      return false;
    }
  }
}

