class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDoctor;
  final String? specialty; // Solo para doctores
  final String? licenseNumber; // Solo para doctores
  final double? rating; // Solo para doctores
  final int? totalAppointments; // Solo para doctores

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    this.isDoctor = false,
    this.specialty,
    this.licenseNumber,
    this.rating,
    this.totalAppointments,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isDoctor: map['isDoctor'] ?? false,
      specialty: map['specialty'],
      licenseNumber: map['licenseNumber'],
      rating: map['rating']?.toDouble(),
      totalAppointments: map['totalAppointments'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDoctor': isDoctor,
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'rating': rating,
      'totalAppointments': totalAppointments,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDoctor,
    String? specialty,
    String? licenseNumber,
    double? rating,
    int? totalAppointments,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDoctor: isDoctor ?? this.isDoctor,
      specialty: specialty ?? this.specialty,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      totalAppointments: totalAppointments ?? this.totalAppointments,
    );
  }
}
