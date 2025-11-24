import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controladores de los campos del formulario
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController enfermedadesController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController lugarNacimientoController = TextEditingController();
  final TextEditingController especialidadController = TextEditingController();
  final TextEditingController licenciaController = TextEditingController();
  String? _selectedRole; // Para el selector de rol

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        nombreController.text = data['name'] ?? '';
        telefonoController.text = data['phone'] ?? '';
        enfermedadesController.text = data['medicalHistory'] ?? '';
        edadController.text = data['age']?.toString() ?? '';
        lugarNacimientoController.text = data['birthplace'] ?? '';
        
        // Cargar rol
        _selectedRole = data['role'] ?? (data['isDoctor'] == true ? 'Médico' : 'Paciente');
        
        // Si es doctor, cargar campos adicionales
        if (data['isDoctor'] == true) {
          especialidadController.text = data['specialty'] ?? '';
          licenciaController.text = data['licenseNumber'] ?? '';
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    }
  }

  // Guardar datos del usuario en Firestore
  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Validar campos
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre no puede estar vacío")),
      );
      return;
    }

    if (telefonoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El teléfono no puede estar vacío")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Obtener el rol actual del usuario (no se puede cambiar)
      final String currentRole = _selectedRole ?? 'Paciente';

      Map<String, dynamic> updateData = {
        'name': nombreController.text.trim(),
        'phone': telefonoController.text.trim(),
        'medicalHistory': enfermedadesController.text.trim(),
        'age': edadController.text.trim().isNotEmpty 
            ? int.tryParse(edadController.text.trim()) 
            : null,
        'birthplace': lugarNacimientoController.text.trim(),
        'email': user.email,
        'id': user.uid,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'role': currentRole,
        'isDoctor': currentRole == 'Médico',
      };

      // Si es doctor, actualizar campos adicionales
      if (currentRole == 'Médico') {
        updateData['specialty'] = especialidadController.text.trim();
        updateData['licenseNumber'] = licenciaController.text.trim();
      }

      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .update(updateData);

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Información guardada exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // true indica que se guardaron cambios
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    enfermedadesController.dispose();
    edadController.dispose();
    lugarNacimientoController.dispose();
    especialidadController.dispose();
    licenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con email (no editable)
                  Card(
                    elevation: 2,
                    color: Colors.indigo.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.email, color: Colors.indigo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Correo electrónico",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  user?.email ?? 'No disponible',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sección de información personal
                  const Text(
                    "Información Personal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FORMULARIO
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: edadController,
                    decoration: const InputDecoration(
                      labelText: 'Edad',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                      helperText: 'Ingresa tu edad en años',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: lugarNacimientoController,
                    decoration: const InputDecoration(
                      labelText: 'Lugar de Nacimiento',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                      helperText: 'Ciudad, Estado, País',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rol (solo lectura - no se puede cambiar)
                  TextFormField(
                    initialValue: _selectedRole ?? 'Paciente',
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      helperText: 'El rol no se puede modificar',
                      filled: true,
                      fillColor: Colors.grey,
                    ),
                    enabled: false,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Campo de enfermedades/historial médico (solo para pacientes)
                  if (_selectedRole != 'Médico') ...[
                    TextField(
                      controller: enfermedadesController,
                      decoration: const InputDecoration(
                        labelText: 'Historial Médico / Enfermedades',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(),
                        helperText: 'Alergias, enfermedades crónicas, medicación actual, etc.',
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Campos adicionales para doctores
                  if (_selectedRole == 'Médico') ...[
                    const Text(
                      "Información Profesional",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: especialidadController,
                      decoration: const InputDecoration(
                        labelText: 'Especialidad',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: licenciaController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Licencia',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Botones de acción
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveUserData,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Guardar Cambios",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text(
                        "Cancelar",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

