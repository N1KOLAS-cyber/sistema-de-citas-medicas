import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/specialty_model.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Stream<QuerySnapshot> _getDoctorsStream() {
    return _firestore
        .collection('users')
        .where('isDoctor', isEqualTo: true)
        .snapshots();
  }

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
                    onPressed: () => _bookAppointment(doctor),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text("Agendar Cita"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
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
              _bookAppointment(doctor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text("Agendar Cita"),
          ),
        ],
      ),
    );
  }

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

  void _bookAppointment(UserModel doctor) {
    // TODO: Implementar agendar cita
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Función de agendar cita con Dr. ${doctor.name} en desarrollo"),
      ),
    );
  }
}
