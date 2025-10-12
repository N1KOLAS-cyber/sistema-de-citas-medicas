import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users Collection
  static const String _usersCollection = 'users';
  static const String _appointmentsCollection = 'appointments';

  // User Methods
  static Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(user.id)
        .set(user.toMap());
  }

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

  // Appointment Methods
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
}
