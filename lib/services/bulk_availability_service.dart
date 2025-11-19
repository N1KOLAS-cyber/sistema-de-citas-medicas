import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/doctor_availability_model.dart';
import '../utils/logger.dart';
import 'firestore_service.dart';

/// Servicio para crear horarios en masa para múltiples doctores
class BulkAvailabilityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Horarios estándar de trabajo (9am - 5pm, cada hora)
  static final List<Map<String, int>> standardWorkHours = [
    {'hour': 9, 'minute': 0},   // 09:00 - 10:00
    {'hour': 10, 'minute': 0},  // 10:00 - 11:00
    {'hour': 11, 'minute': 0},  // 11:00 - 12:00
    {'hour': 12, 'minute': 0},  // 12:00 - 13:00
    {'hour': 13, 'minute': 0},  // 13:00 - 14:00
    {'hour': 14, 'minute': 0},  // 14:00 - 15:00
    {'hour': 15, 'minute': 0},  // 15:00 - 16:00
    {'hour': 16, 'minute': 0},  // 16:00 - 17:00
  ];

  /// Crear horarios para todos los doctores del sistema
  /// para los próximos N días
  static Future<Map<String, dynamic>> createScheduleForAllDoctors({
    required int daysAhead,
    DateTime? startDate,
  }) async {
    try {
      logInfo('🔄 Iniciando creación masiva de horarios...\n');

      DateTime baseDate = startDate ?? DateTime.now().add(const Duration(days: 1));
      
      // Obtener todos los doctores
      QuerySnapshot doctorsSnapshot = await _firestore
          .collection('usuarios')
          .where('isDoctor', isEqualTo: true)
          .get();

      if (doctorsSnapshot.docs.isEmpty) {
        logInfo('⚠️ No se encontraron doctores en el sistema');
        return {'success': false, 'error': 'No hay doctores'};
      }

      List<UserModel> doctors = doctorsSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      logInfo('👨‍⚕️ Encontrados ${doctors.length} doctores');
      logInfo('📅 Creando horarios para los próximos $daysAhead días\n');

      int totalSlotsCreated = 0;
      int totalDoctorsProcessed = 0;

      for (UserModel doctor in doctors) {
        logInfo('Procesando: Dr. ${doctor.name} (${doctor.specialty})');
        
        int slotsForDoctor = 0;

        // Crear horarios para los próximos N días
        for (int day = 0; day < daysAhead; day++) {
          DateTime targetDate = DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day + day,
          );

          // Verificar si ya existen horarios para este día
          List<DoctorAvailabilityModel> existingSlots = 
              await FirestoreService.getDoctorAvailabilityByDate(
                doctor.id,
                targetDate,
              );

          if (existingSlots.isNotEmpty) {
            logInfo('  ⏭️  ${_formatDate(targetDate)}: Ya tiene ${existingSlots.length} horarios, saltando...');
            continue;
          }

          // Crear horarios para este día
          List<Map<String, DateTime>> timeSlots = [];
          
          for (var hourConfig in standardWorkHours) {
            DateTime startTime = DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
              hourConfig['hour']!,
              hourConfig['minute']!,
            );
            
            DateTime endTime = startTime.add(const Duration(hours: 1));
            
            timeSlots.add({
              'start': startTime,
              'end': endTime,
            });
          }

          try {
            await FirestoreService.createBulkAvailability(
              doctor.id,
              doctor.name,
              targetDate,
              timeSlots,
            );
            
            slotsForDoctor += timeSlots.length;
            logInfo('  ✅ ${_formatDate(targetDate)}: ${timeSlots.length} horarios creados');
          } catch (e) {
            logInfo('  ❌ Error en ${_formatDate(targetDate)}: $e');
          }
        }

        totalSlotsCreated += slotsForDoctor;
        totalDoctorsProcessed++;
        logInfo('  Total: $slotsForDoctor horarios creados para este doctor\n');
      }

      logInfo('════════════════════════════════════════');
      logInfo('✅ PROCESO COMPLETADO');
      logInfo('════════════════════════════════════════');
      logInfo('Doctores procesados: $totalDoctorsProcessed');
      logInfo('Total de horarios creados: $totalSlotsCreated');
      logInfo('Promedio por doctor: ${(totalSlotsCreated / totalDoctorsProcessed).toStringAsFixed(0)}');
      logInfo('════════════════════════════════════════\n');

      return {
        'success': true,
        'doctorsProcessed': totalDoctorsProcessed,
        'totalSlots': totalSlotsCreated,
      };
    } catch (e) {
      logInfo('❌ Error en creación masiva: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Crear horarios para un doctor específico para los próximos N días
  static Future<int> createScheduleForDoctor({
    required String doctorId,
    required String doctorName,
    required int daysAhead,
  }) async {
    try {
      DateTime baseDate = DateTime.now().add(const Duration(days: 1));
      int totalCreated = 0;

      for (int day = 0; day < daysAhead; day++) {
        DateTime targetDate = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + day,
        );

        // Verificar si ya existen horarios
        List<DoctorAvailabilityModel> existingSlots = 
            await FirestoreService.getDoctorAvailabilityByDate(
              doctorId,
              targetDate,
            );

        if (existingSlots.isNotEmpty) continue;

        // Crear horarios
        List<Map<String, DateTime>> timeSlots = [];
        
        for (var hourConfig in standardWorkHours) {
          DateTime startTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            hourConfig['hour']!,
            hourConfig['minute']!,
          );
          
          DateTime endTime = startTime.add(const Duration(hours: 1));
          
          timeSlots.add({
            'start': startTime,
            'end': endTime,
          });
        }

        await FirestoreService.createBulkAvailability(
          doctorId,
          doctorName,
          targetDate,
          timeSlots,
        );

        totalCreated += timeSlots.length;
      }

      return totalCreated;
    } catch (e) {
      logInfo('Error al crear horarios: $e');
      return 0;
    }
  }

  /// Eliminar TODOS los horarios disponibles (no ocupados) de un doctor
  static Future<int> deleteAllAvailableSlotsForDoctor(String doctorId) async {
    try {
      QuerySnapshot slotsSnapshot = await _firestore
          .collection('disponibilidad_medicos')
          .where('doctorId', isEqualTo: doctorId)
          .where('isAvailable', isEqualTo: true)
          .get();

      int deletedCount = 0;

      for (var doc in slotsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      logInfo('Error al eliminar horarios: $e');
      return 0;
    }
  }

  /// Obtener estadísticas de horarios de todos los doctores
  static Future<Map<String, dynamic>> getAvailabilityStats() async {
    try {
      QuerySnapshot allSlots = await _firestore
          .collection('disponibilidad_medicos')
          .get();

      int totalSlots = allSlots.docs.length;
      int availableSlots = allSlots.docs.where((doc) {
        return (doc.data() as Map<String, dynamic>)['isAvailable'] == true;
      }).length;
      int occupiedSlots = totalSlots - availableSlots;

      return {
        'total': totalSlots,
        'available': availableSlots,
        'occupied': occupiedSlots,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

