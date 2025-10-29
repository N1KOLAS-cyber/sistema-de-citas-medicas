/**
 * FIRESTORE SERVICE - SERVICIO DE BASE DE DATOS
 * 
 * Este archivo contiene todas las operaciones de base de datos con Firestore.
 * Maneja usuarios, citas y disponibilidad de doctores.
 * 
 * FUNCIONALIDADES:
 * - CRUD completo para usuarios (pacientes y doctores)
 * - CRUD completo para citas médicas
 * - Gestión de disponibilidad de doctores
 * - Consultas especializadas por filtros
 * - Operaciones en lote para eficiencia
 * 
 * ESTRUCTURA:
 * - Métodos de usuarios: createUser, getUser, updateUser, getDoctors
 * - Métodos de citas: createAppointment, updateAppointment, getUserAppointments
 * - Métodos de disponibilidad: createAvailability, getAvailableSlots
 * - Helpers para formateo y validación
 * 
 * VISUALIZACIÓN: Servicio que actúa como capa de abstracción entre
 * la aplicación y Firestore, proporcionando métodos simplificados
 * para todas las operaciones de base de datos.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/doctor_availability_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _usersCollection = 'usuarios'; // Colección de usuarios
  static const String _appointmentsCollection = 'citas'; // Colección de citas
  static const String _availabilityCollection = 'disponibilidad_medicos'; // Colección de disponibilidad

  // ========== MÉTODOS DE USUARIOS ==========
  
  /**
   * Crea un nuevo usuario en Firestore
   * @param user - Modelo del usuario a crear
   */
  static Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(user.id)
        .set(user.toMap());
  }

  /**
   * Obtiene un usuario por su ID
   * @param userId - ID del usuario
   * @return UserModel? - Usuario encontrado o null
   */
  static Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .get();
    
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  static Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(user.id)
        .update(user.toMap());
  }

  static Stream<List<UserModel>> getDoctors() {
    return _firestore
        .collection(_usersCollection)
        .where('isDoctor', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  static Stream<List<UserModel>> getDoctorsBySpecialty(String specialty) {
    return _firestore
        .collection(_usersCollection)
        .where('isDoctor', isEqualTo: true)
        .where('specialty', isEqualTo: specialty)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // ========== MÉTODOS DE CITAS ==========
  
  /**
   * Crea una nueva cita en Firestore
   * @param appointment - Modelo de la cita a crear
   */
  static Future<void> createAppointment(AppointmentModel appointment) async {
    await _firestore
        .collection(_appointmentsCollection)
        .doc(appointment.id)
        .set(appointment.toMap());
  }

  static Future<void> updateAppointment(AppointmentModel appointment) async {
    await _firestore
        .collection(_appointmentsCollection)
        .doc(appointment.id)
        .update(appointment.toMap());
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    await _firestore
        .collection(_appointmentsCollection)
        .doc(appointmentId)
        .delete();
  }

  static Stream<List<AppointmentModel>> getUserAppointments(String userId) {
    return _firestore
        .collection(_appointmentsCollection)
        .where('patientId', isEqualTo: userId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data()))
            .toList());
  }

  static Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    return _firestore
        .collection(_appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data()))
            .toList());
  }

  static Stream<List<AppointmentModel>> getAppointmentsByStatus(
    String userId,
    AppointmentStatus status,
  ) {
    return _firestore
        .collection(_appointmentsCollection)
        .where('patientId', isEqualTo: userId)
        .where('status', isEqualTo: status.name)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data()))
            .toList());
  }

  static Future<List<AppointmentModel>> getAppointmentsByDate(
    String doctorId,
    DateTime date,
  ) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    QuerySnapshot snapshot = await _firestore
        .collection(_appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .where('appointmentDate', isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
        .get();

    return snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ========== MÉTODOS DE DISPONIBILIDAD ==========
  
  /**
   * Crea un nuevo horario de disponibilidad para un doctor
   * @param availability - Modelo de disponibilidad a crear
   */
  static Future<void> createAvailability(DoctorAvailabilityModel availability) async {
    await _firestore
        .collection(_availabilityCollection)
        .doc(availability.id)
        .set(availability.toMap());
  }

  static Future<void> updateAvailability(DoctorAvailabilityModel availability) async {
    await _firestore
        .collection(_availabilityCollection)
        .doc(availability.id)
        .update(availability.toMap());
  }

  static Future<void> deleteAvailability(String availabilityId) async {
    await _firestore
        .collection(_availabilityCollection)
        .doc(availabilityId)
        .delete();
  }

  // Obtener disponibilidad de un médico en una fecha específica
  static Future<List<DoctorAvailabilityModel>> getDoctorAvailabilityByDate(
    String doctorId,
    DateTime date,
  ) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    QuerySnapshot snapshot = await _firestore
        .collection(_availabilityCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
        .orderBy('date')
        .orderBy('startTime')
        .get();

    return snapshot.docs
        .map((doc) => DoctorAvailabilityModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Obtener solo horarios disponibles de un médico
  static Stream<List<DoctorAvailabilityModel>> getAvailableSlots(
    String doctorId,
    DateTime date,
  ) {
    // Consulta simplificada: solo filtrar por doctorId y isAvailable
    // Luego filtrar por fecha en el código (evita índices complejos)
    return _firestore
        .collection(_availabilityCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          // Filtrar por fecha en el código (lado del cliente)
          List<DoctorAvailabilityModel> allSlots = snapshot.docs
              .map((doc) => DoctorAvailabilityModel.fromMap(doc.data()))
              .toList();
          
          // Filtrar solo los del día seleccionado
          List<DoctorAvailabilityModel> daySlots = allSlots.where((slot) {
            return slot.date.year == date.year &&
                   slot.date.month == date.month &&
                   slot.date.day == date.day;
          }).toList();
          
          // Ordenar por hora de inicio
          daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));
          
          return daySlots;
        });
  }

  // Verificar si un horario está disponible
  static Future<bool> isTimeSlotAvailable(
    String doctorId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    // Consulta simplificada: obtener todos los horarios disponibles del doctor
    // y verificar en el código
    QuerySnapshot snapshot = await _firestore
        .collection(_availabilityCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('isAvailable', isEqualTo: true)
        .get();

    // Verificar en el código si algún horario coincide
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      
      // Parsear las fechas del documento
      DateTime slotStart;
      DateTime slotEnd;
      
      try {
        if (data['startTime'] is int) {
          slotStart = DateTime.fromMillisecondsSinceEpoch(data['startTime']);
          slotEnd = DateTime.fromMillisecondsSinceEpoch(data['endTime']);
        } else {
          slotStart = (data['startTime'] as dynamic).toDate();
          slotEnd = (data['endTime'] as dynamic).toDate();
        }
        
        // Verificar si este horario coincide con el solicitado
        if (slotStart.isAtSameMomentAs(startTime) && slotEnd.isAtSameMomentAs(endTime)) {
          return true;
        }
      } catch (e) {
        continue;
      }
    }

    return false;
  }

  // Marcar horario como no disponible (cuando se crea una cita)
  static Future<void> markSlotAsUnavailable(
    String availabilityId,
    String appointmentId,
  ) async {
    await _firestore
        .collection(_availabilityCollection)
        .doc(availabilityId)
        .update({
      'isAvailable': false,
      'appointmentId': appointmentId,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Marcar horario como disponible (cuando se cancela una cita)
  static Future<void> markSlotAsAvailable(String availabilityId) async {
    await _firestore
        .collection(_availabilityCollection)
        .doc(availabilityId)
        .update({
      'isAvailable': true,
      'appointmentId': null,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Crear horarios disponibles para un médico (batch creation)
  static Future<void> createBulkAvailability(
    String doctorId,
    String doctorName,
    DateTime date,
    List<Map<String, DateTime>> timeSlots, // [{start: DateTime, end: DateTime}]
  ) async {
    WriteBatch batch = _firestore.batch();

    for (var slot in timeSlots) {
      String id = _firestore.collection(_availabilityCollection).doc().id;
      
      DoctorAvailabilityModel availability = DoctorAvailabilityModel(
        id: id,
        doctorId: doctorId,
        doctorName: doctorName,
        date: date,
        timeSlot: _formatTimeSlot(slot['start']!, slot['end']!),
        startTime: slot['start']!,
        endTime: slot['end']!,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      batch.set(
        _firestore.collection(_availabilityCollection).doc(id),
        availability.toMap(),
      );
    }

    await batch.commit();
  }

  // Helper para formatear horario
  static String _formatTimeSlot(DateTime start, DateTime end) {
    String formatTime(DateTime time) {
      String hour = time.hour.toString().padLeft(2, '0');
      String minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${formatTime(start)} - ${formatTime(end)}';
  }
}
