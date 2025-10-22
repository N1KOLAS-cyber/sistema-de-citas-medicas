class DoctorAvailabilityModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final String timeSlot; // Ej: "09:00 - 10:00"
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? appointmentId; // ID de la cita si está ocupado
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorAvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.appointmentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorAvailabilityModel.fromMap(Map<String, dynamic> map) {
    // Helper para convertir cualquier formato de fecha a DateTime
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is DateTime) return value;
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    return DoctorAvailabilityModel(
      id: map['id'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      date: parseDate(map['date']),
      timeSlot: map['timeSlot'] ?? '',
      startTime: parseDate(map['startTime']),
      endTime: parseDate(map['endTime']),
      isAvailable: map['isAvailable'] ?? true,
      appointmentId: map['appointmentId'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': date.millisecondsSinceEpoch,
      'timeSlot': timeSlot,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'isAvailable': isAvailable,
      'appointmentId': appointmentId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  DoctorAvailabilityModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    DateTime? date,
    String? timeSlot,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
    String? appointmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorAvailabilityModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      appointmentId: appointmentId ?? this.appointmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Método helper para verificar si el horario está en conflicto con otro
  bool hasConflictWith(DateTime checkStart, DateTime checkEnd) {
    return (checkStart.isBefore(endTime) && checkEnd.isAfter(startTime));
  }

  // Método helper para formatear la fecha
  String get formattedDate {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Método helper para obtener el día de la semana
  String get dayOfWeek {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }
}

