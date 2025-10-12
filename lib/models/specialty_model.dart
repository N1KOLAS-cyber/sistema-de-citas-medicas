class SpecialtyModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double basePrice;
  final int averageDuration; // en minutos
  final bool isActive;

  SpecialtyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.basePrice,
    required this.averageDuration,
    this.isActive = true,
  });

  factory SpecialtyModel.fromMap(Map<String, dynamic> map) {
    return SpecialtyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'medical_services',
      basePrice: map['basePrice']?.toDouble() ?? 0.0,
      averageDuration: map['averageDuration'] ?? 30,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'basePrice': basePrice,
      'averageDuration': averageDuration,
      'isActive': isActive,
    };
  }

  SpecialtyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    double? basePrice,
    int? averageDuration,
    bool? isActive,
  }) {
    return SpecialtyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      basePrice: basePrice ?? this.basePrice,
      averageDuration: averageDuration ?? this.averageDuration,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Especialidades predefinidas
class MedicalSpecialties {
  static final List<SpecialtyModel> specialties = [
    SpecialtyModel(
      id: '1',
      name: 'Medicina General',
      description: 'Atención médica integral para pacientes de todas las edades',
      icon: 'medical_services',
      basePrice: 50.0,
      averageDuration: 30,
    ),
    SpecialtyModel(
      id: '2',
      name: 'Cardiología',
      description: 'Especialidad en enfermedades del corazón y sistema cardiovascular',
      icon: 'favorite',
      basePrice: 80.0,
      averageDuration: 45,
    ),
    SpecialtyModel(
      id: '3',
      name: 'Dermatología',
      description: 'Diagnóstico y tratamiento de enfermedades de la piel',
      icon: 'face',
      basePrice: 60.0,
      averageDuration: 30,
    ),
    SpecialtyModel(
      id: '4',
      name: 'Pediatría',
      description: 'Atención médica especializada para niños y adolescentes',
      icon: 'child_care',
      basePrice: 55.0,
      averageDuration: 30,
    ),
    SpecialtyModel(
      id: '5',
      name: 'Ginecología',
      description: 'Salud reproductiva y ginecológica de la mujer',
      icon: 'pregnant_woman',
      basePrice: 70.0,
      averageDuration: 40,
    ),
    SpecialtyModel(
      id: '6',
      name: 'Ortopedia',
      description: 'Tratamiento de lesiones y enfermedades del sistema musculoesquelético',
      icon: 'accessibility',
      basePrice: 75.0,
      averageDuration: 45,
    ),
    SpecialtyModel(
      id: '7',
      name: 'Neurología',
      description: 'Diagnóstico y tratamiento de enfermedades del sistema nervioso',
      icon: 'psychology',
      basePrice: 90.0,
      averageDuration: 60,
    ),
    SpecialtyModel(
      id: '8',
      name: 'Oftalmología',
      description: 'Cuidado de la salud visual y tratamiento de enfermedades oculares',
      icon: 'visibility',
      basePrice: 65.0,
      averageDuration: 30,
    ),
  ];
}
