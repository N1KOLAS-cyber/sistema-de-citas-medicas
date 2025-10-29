/**
 * DOCTORS PAGE - PÁGINA DE LISTADO DE DOCTORES
 * 
 * Este archivo contiene la página que muestra la lista de doctores disponibles.
 * Permite buscar, filtrar por especialidad y agendar citas.
 * 
 * FUNCIONALIDADES:
 * - Lista de doctores con información detallada
 * - Búsqueda por nombre y especialidad
 * - Filtros por especialidad médica
 * - Visualización de perfil del doctor
 * - Agendamiento directo de citas
 * - Calificaciones y estadísticas
 * 
 * ESTRUCTURA:
 * - Barra de búsqueda
 * - Filtros de especialidad
 * - Lista de doctores con tarjetas
 * - Diálogos de perfil y agendamiento
 * 
 * VISUALIZACIÓN: Página con diseño de tarjetas, filtros horizontales,
 * búsqueda en tiempo real y información detallada de cada doctor.
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/specialty_model.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedSpecialty = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctores"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar doctores...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Filtro de especialidades
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: MedicalSpecialties.specialties.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text("Todas"),
                      selected: _selectedSpecialty == 'Todas',
                      onSelected: (selected) {
                        setState(() {
                          _selectedSpecialty = 'Todas';
                        });
                      },
                      selectedColor: Colors.indigo.withOpacity(0.2),
                      checkmarkColor: Colors.indigo,
                    ),
                  );
                }
                
                final specialty = MedicalSpecialties.specialties[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(specialty.name),
                    selected: _selectedSpecialty == specialty.name,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSpecialty = specialty.name;
                      });
                    },
                    selectedColor: Colors.indigo.withOpacity(0.2),
                    checkmarkColor: Colors.indigo,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Lista de doctores
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getDoctorsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.medical_services, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay doctores disponibles',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Intenta con otra especialidad',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                List<UserModel> doctors = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                // Filtrar doctores
                doctors = _filterDoctors(doctors);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    return _buildDoctorCard(doctors[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /**
   * Obtiene el stream de doctores desde Firestore
   * @return Stream<QuerySnapshot> - Stream de doctores
   */
  Stream<QuerySnapshot> _getDoctorsStream() {
    return _firestore
        .collection('usuarios')
        .where('isDoctor', isEqualTo: true)
        .snapshots();
  }

  /**
   * Filtra la lista de doctores según especialidad y búsqueda
   * @param doctors - Lista de doctores a filtrar
   * @return List<UserModel> - Lista filtrada de doctores
   */
  List<UserModel> _filterDoctors(List<UserModel> doctors) {
    // Filtrar por especialidad
    if (_selectedSpecialty != 'Todas') {
      doctors = doctors.where((doctor) => doctor.specialty == _selectedSpecialty).toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      doctors = doctors.where((doctor) {
        return doctor.name.toLowerCase().contains(searchTerm) ||
               doctor.specialty?.toLowerCase().contains(searchTerm) == true;
      }).toList();
    }

    return doctors;
  }

  /**
   * Construye la tarjeta de información de un doctor
   * @param doctor - Modelo del doctor a mostrar
   * @return Widget - Tarjeta con información del doctor
   */
  Widget _buildDoctorCard(UserModel doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar del doctor
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: doctor.profileImage != null
                      ? ClipOval(
                          child: Image.network(
                            doctor.profileImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.indigo,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.indigo,
                        ),
                ),
                const SizedBox(width: 16),

                // Información del doctor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. ${doctor.name}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialty ?? 'Especialidad no especificada',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Calificación
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            doctor.rating?.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "(${doctor.totalAppointments ?? 0} citas)",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información adicional
            Row(
              children: [
                Icon(Icons.badge, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  "Licencia: ${doctor.licenseNumber ?? 'No disponible'}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDoctorProfile(doctor),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text("Ver Perfil"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRatingButton(doctor),
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text("Calificar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Muestra el perfil detallado de un doctor en un diálogo
   * @param doctor - Doctor del cual mostrar el perfil
   */
  void _viewDoctorProfile(UserModel doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Dr. ${doctor.name}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProfileDetail("Especialidad:", doctor.specialty ?? 'No especificada'),
              _buildProfileDetail("Licencia:", doctor.licenseNumber ?? 'No disponible'),
              _buildProfileDetail("Calificación:", "${doctor.rating?.toStringAsFixed(1) ?? '0.0'} ⭐"),
              _buildProfileDetail("Citas Atendidas:", "${doctor.totalAppointments ?? 0}"),
              _buildProfileDetail("Teléfono:", doctor.phone),
              _buildProfileDetail("Email:", doctor.email),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRatingButton(doctor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text("Calificar"),
          ),
        ],
      ),
    );
  }

  /**
   * Construye una fila de detalle del perfil
   * @param label - Etiqueta del campo
   * @param value - Valor del campo
   * @return Widget - Fila de detalle
   */
  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /**
   * Decide si mostrar el botón de puntuar o solo ver calificaciones
   * @param doctor - Doctor a evaluar
   */
  void _showRatingButton(UserModel doctor) async {
    // Verificar si el usuario actual es doctor
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await _firestore
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final isCurrentUserDoctor = userData['isDoctor'] ?? false;
          
          if (isCurrentUserDoctor) {
            // Si es doctor, solo mostrar calificaciones
            _viewDoctorRating(doctor);
            return;
          }
        }
      } catch (e) {
        // Si hay error al verificar, permitir la puntuación
        print('Error verificando usuario: $e');
      }
    }

    // Si no es doctor, permitir puntuar
    _rateDoctor(doctor);
  }

  /**
   * Muestra las calificaciones del doctor sin permitir puntuar
   * @param doctor - Doctor del cual mostrar calificaciones
   */
  void _viewDoctorRating(UserModel doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Calificaciones - Dr. ${doctor.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calificación actual
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.orange, size: 30),
                const SizedBox(width: 8),
                Text(
                  "${doctor.rating?.toStringAsFixed(1) ?? '0.0'}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "/ 5.0",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Número de citas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "${doctor.totalAppointments ?? 0} citas atendidas",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Mensaje informativo
            Text(
              "Esta calificación se basa en las evaluaciones de los pacientes que han tenido consultas con este doctor.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  /**
   * Muestra el diálogo para puntuar a un doctor
   * Permite al usuario calificar al doctor y actualizar su puntuación
   * @param doctor - Doctor a puntuar
   */
  void _rateDoctor(UserModel doctor) async {
    // Verificar si el usuario actual es doctor
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await _firestore
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final isCurrentUserDoctor = userData['isDoctor'] ?? false;
          
          if (isCurrentUserDoctor) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Los doctores no pueden puntuar a otros doctores"),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
      } catch (e) {
        // Si hay error al verificar, permitir la puntuación
        print('Error verificando usuario: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => _RatingDialog(doctor: doctor, onSubmit: _submitRating),
    );
  }

  /**
   * Envía la puntuación del doctor y actualiza su calificación promedio
   * @param doctor - Doctor a calificar
   * @param rating - Puntuación dada (1-5)
   */
  void _submitRating(UserModel doctor, double rating) async {
    if (!mounted) return;
    
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener datos del usuario actual
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes iniciar sesión para puntuar"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Actualizar la calificación del doctor
      await _updateDoctorRating(doctor.id, rating);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Gracias por puntuar a Dr. ${doctor.name}!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        // Asegurarse de cerrar el loading si está abierto
        try {
          Navigator.of(context).pop(); // Cerrar loading
        } catch (_) {
          // Si ya estaba cerrado, ignorar el error
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al enviar puntuación: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Actualiza la calificación promedio del doctor en Firestore
   * @param doctorId - ID del doctor
   * @param newRating - Nueva puntuación
   */
  Future<void> _updateDoctorRating(String doctorId, double newRating) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Usar una subcolección de calificaciones para evitar problemas de permisos
      // Cada calificación se guarda como un documento separado
      final ratingDocRef = _firestore
          .collection('usuarios')
          .doc(doctorId)
          .collection('ratings')
          .doc();
      
      // Guardar la calificación individual
      await ratingDocRef.set({
        'rating': newRating,
        'userId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Calcular el promedio leyendo todas las calificaciones
      final ratingsSnapshot = await _firestore
          .collection('usuarios')
          .doc(doctorId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        throw Exception('No se pudo obtener las calificaciones');
      }

      double totalRating = 0.0;
      int count = 0;
      
      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final rating = data['rating'];
        if (rating != null) {
          totalRating += (rating as num).toDouble();
          count++;
        }
      }

      final averageRating = count > 0 ? totalRating / count : 0.0;

      // Actualizar el promedio en el documento del doctor
      // Esto requiere permisos, pero al menos intentamos actualizar
      try {
        await _firestore.collection('usuarios').doc(doctorId).update({
          'rating': averageRating,
          'totalAppointments': count,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        // Si falla la actualización del promedio, al menos guardamos la calificación
        // El promedio se puede recalcular cuando se lea
        print('Error al actualizar promedio, pero la calificación se guardó: $updateError');
      }
    } catch (e) {
      throw Exception('Error al actualizar calificación: $e');
    }
  }
}

/**
 * Widget de diálogo para puntuar doctores
 * Maneja el estado de las estrellas de forma independiente
 */
class _RatingDialog extends StatefulWidget {
  final UserModel doctor;
  final Function(UserModel doctor, double rating) onSubmit;

  const _RatingDialog({
    required this.doctor,
    required this.onSubmit,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double currentRating = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Puntuar Dr. ${widget.doctor.name}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "¿Cómo calificarías la atención de este doctor?",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentRating = (index + 1).toDouble();
                  });
                },
                child: Icon(
                  Icons.star,
                  size: 40,
                  color: index < currentRating 
                      ? Colors.orange 
                      : Colors.grey[300],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            currentRating > 0 
                ? "${currentRating.toInt()} estrella${currentRating > 1 ? 's' : ''}"
                : "Selecciona una puntuación",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: currentRating > 0 ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: currentRating > 0 
              ? () {
                  // Cerrar diálogo primero
                  Navigator.of(context).pop();
                  // Luego enviar la puntuación
                  widget.onSubmit(widget.doctor, currentRating);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text("Enviar Puntuación"),
        ),
      ],
    );
  }
}
