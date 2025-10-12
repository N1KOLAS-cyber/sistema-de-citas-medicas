enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

enum AppointmentType {
  consultation,
  followUp,
  emergency,
  routine,
}

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String specialty;
  final DateTime appointmentDate;
  final String timeSlot;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? notes;
  final String? symptoms;
  final String? diagnosis;
  final String? prescription;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    required this.type,
    this.notes,
    this.symptoms,
    this.diagnosis,
    this.prescription,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorName: map['doctorName'] ?? '',
      specialty: map['specialty'] ?? '',
      appointmentDate: DateTime.fromMillisecondsSinceEpoch(map['appointmentDate'] ?? 0),
      timeSlot: map['timeSlot'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      type: AppointmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AppointmentType.consultation,
      ),
      notes: map['notes'],
      symptoms: map['symptoms'],
      diagnosis: map['diagnosis'],
      prescription: map['prescription'],
      cost: map['cost']?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentDate': appointmentDate.millisecondsSinceEpoch,
      'timeSlot': timeSlot,
      'status': status.name,
      'type': type.name,
      'notes': notes,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'cost': cost,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? specialty,
    DateTime? appointmentDate,
    String? timeSlot,
    AppointmentStatus? status,
    AppointmentType? type,
    String? notes,
    String? symptoms,
    String? diagnosis,
    String? prescription,
    double? cost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusText {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
    }
  }

  String get typeText {
    switch (type) {
      case AppointmentType.consultation:
        return 'Consulta';
      case AppointmentType.followUp:
        return 'Seguimiento';
      case AppointmentType.emergency:
        return 'Emergencia';
      case AppointmentType.routine:
        return 'Rutina';
    }
  }
}
