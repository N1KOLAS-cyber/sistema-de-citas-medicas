/**
 * APPOINTMENTS PAGE - PÁGINA DE CITAS DEL USUARIO
 * 
 * Este archivo contiene la página que muestra las citas del usuario actual.
 * Permite ver, filtrar y gestionar las citas médicas.
 * 
 * FUNCIONALIDADES:
 * - Lista de citas del usuario con información detallada
 * - Filtros por estado (Todas, Próximas, Canceladas)
 * - Visualización de detalles completos de cada cita
 * - Cancelación de citas (funcionalidad en desarrollo)
 * - Navegación a creación de nuevas citas
 * - Acceso a mensajes con doctores
 * 
 * ESTRUCTURA:
 * - AppBar con filtros desplegables
 * - Lista de citas con tarjetas informativas
 * - Botones flotantes para acciones rápidas
 * - Diálogos de confirmación y detalles
 * 
 * VISUALIZACIÓN: Página con diseño de tarjetas, filtros intuitivos,
 * información clara de cada cita y botones de acción contextuales.
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import 'create_appointment_page.dart';
import 'messages_page.dart';
import 'doctor_appointments_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'Todas'; // Por defecto mostrar todas las citas
  bool _isDoctor = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  /**
   * Verifica si el usuario actual es doctor
   */
  Future<void> _checkUserType() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await _firestore
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final isDoctor = userData['isDoctor'] ?? false;
          
          if (mounted) {
            setState(() {
              _isDoctor = isDoctor;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando, mostrar indicador de carga
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mis Citas"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si es doctor, mostrar la página de gestión de citas para doctores
    if (_isDoctor) {
      return const DoctorAppointmentsPage();
    }

    // Si es paciente, mostrar la página de citas normal
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Citas"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Botón de chat
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesPage(),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            tooltip: 'Chat con doctores',
          ),
          // Menú de filtros
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Todas', child: Text('Todas')),
              const PopupMenuItem(value: 'Próximas', child: Text('Próximas')),
              const PopupMenuItem(value: 'Canceladas', child: Text('Canceladas')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedFilter),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAppointmentsStream(),
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
                  const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes citas programadas',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agenda tu primera cita médica',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          List<AppointmentModel> appointments = snapshot.data!.docs
              .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Ordenar por fecha en memoria (más recientes primero)
          appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

          // Filtrar citas según el filtro seleccionado
          if (_selectedFilter == 'Próximas') {
            // Mostrar solo citas futuras (pendientes o confirmadas)
            DateTime now = DateTime.now();
            appointments = appointments.where((appointment) {
              return appointment.appointmentDate.isAfter(now) &&
                     (appointment.status == AppointmentStatus.pending ||
                      appointment.status == AppointmentStatus.confirmed);
            }).toList();
          } else if (_selectedFilter == 'Canceladas') {
            // Mostrar solo citas canceladas
            appointments = appointments.where((appointment) {
              return appointment.status == AppointmentStatus.cancelled;
            }).toList();
          }
          // Si es 'Todas', no filtrar nada

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(appointments[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateOrEditDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        tooltip: 'Agendar o editar cita',
      ),
    );
  }

  /**
   * Obtiene el stream de citas del usuario actual desde Firestore
   * @return Stream<QuerySnapshot> - Stream de citas del usuario
   */
  Stream<QuerySnapshot> _getAppointmentsStream() {
    User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      // Si no hay usuario autenticado, retornar stream vacío
      return _firestore
          .collection('citas')
          .where('patientId', isEqualTo: 'no-user')
          .snapshots();
    }

    // Filtrar citas donde el usuario es paciente
    // Removemos orderBy para evitar necesidad de índice compuesto, ordenamos en memoria
    return _firestore
        .collection('citas')
        .where('patientId', isEqualTo: currentUser.uid)
        .snapshots();
  }

  /**
   * Construye la tarjeta de información de una cita
   * @param appointment - Modelo de la cita a mostrar
   * @return Widget - Tarjeta con información de la cita
   */
  Widget _buildAppointmentCard(AppointmentModel appointment) {
    Color statusColor = _getStatusColor(appointment.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    appointment.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  appointment.typeText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información del doctor/paciente
            Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: Colors.indigo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.doctorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.work,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.specialty,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fecha y hora
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(appointment.appointmentDate),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.timeSlot,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            // Notas si existen
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Notas:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.notes!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botones de acción
            if (appointment.status == AppointmentStatus.pending ||
                appointment.status == AppointmentStatus.confirmed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelAppointment(appointment),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _viewAppointmentDetails(appointment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Ver Detalles"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /**
   * Obtiene el color correspondiente al estado de una cita
   * @param status - Estado de la cita
   * @return Color - Color representativo del estado
   */
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  /**
   * Formatea una fecha para mostrar en la interfaz
   * @param date - Fecha a formatear
   * @return String - Fecha formateada
   */
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  /**
   * Muestra diálogo de confirmación para cancelar una cita
   * @param appointment - Cita a cancelar
   */
  void _cancelAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancelar Cita"),
        content: const Text("¿Estás seguro de que quieres cancelar esta cita?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performCancelAppointment(appointment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Sí, Cancelar"),
          ),
        ],
      ),
    );
  }

  /**
   * Realiza la cancelación de una cita
   * @param appointment - Cita a cancelar
   */
  Future<void> _performCancelAppointment(AppointmentModel appointment) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Actualizar el estado en Firestore marcando que fue cancelada por el paciente
      await _firestore.collection('citas').doc(appointment.id).update({
        'status': 'cancelled',
        'cancelledBy': 'patient',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Cerrar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cita cancelada exitosamente"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si hay error
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cancelar cita: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Muestra los detalles completos de una cita en un diálogo
   * @param appointment - Cita de la cual mostrar detalles
   */
  void _viewAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Detalles de la Cita"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow("Doctor:", appointment.doctorName),
              _buildDetailRow("Especialidad:", appointment.specialty),
              _buildDetailRow("Fecha:", _formatDate(appointment.appointmentDate)),
              _buildDetailRow("Hora:", appointment.timeSlot),
              _buildDetailRow("Estado:", appointment.statusText),
              _buildDetailRow("Tipo:", appointment.typeText),
              if (appointment.notes != null)
                _buildDetailRow("Notas:", appointment.notes!),
              if (appointment.symptoms != null)
                _buildDetailRow("Síntomas:", appointment.symptoms!),
              if (appointment.diagnosis != null)
                _buildDetailRow("Diagnóstico:", appointment.diagnosis!),
              if (appointment.prescription != null)
                _buildDetailRow("Prescripción:", appointment.prescription!),
              if (appointment.cost != null)
                _buildDetailRow("Costo:", "\$${appointment.cost!.toStringAsFixed(2)}"),
            ],
          ),
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
   * Construye una fila de detalle para mostrar información
   * @param label - Etiqueta del campo
   * @param value - Valor del campo
   * @return Widget - Fila de detalle
   */
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
   * Muestra un diálogo para crear nueva cita o editar una existente
   */
  void _showCreateOrEditDialog() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontraron datos del usuario")),
        );
        return;
      }

      final userData = userDoc.data()!;
      final user = UserModel.fromMap(userData);

      // Obtener citas editables (pendientes o confirmadas, futuras)
      // Removemos orderBy para evitar necesidad de índice compuesto, ordenamos en memoria
      final appointmentsSnapshot = await _firestore
          .collection('citas')
          .where('patientId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      List<AppointmentModel> editableAppointments = appointmentsSnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .where((appointment) => appointment.appointmentDate.isAfter(DateTime.now()))
          .toList();
      
      // Ordenar por fecha en memoria
      editableAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      if (editableAppointments.isEmpty) {
        // Si no hay citas editables, ir directamente a crear nueva cita
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAppointmentPage(patient: user),
          ),
        );
        return;
      }

      // Mostrar diálogo con opciones
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Gestionar Citas"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.indigo),
                title: const Text("Crear Nueva Cita"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAppointmentPage(patient: user),
                    ),
                  );
                },
              ),
              const Divider(),
              const Text(
                "Editar Cita Existente:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: editableAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = editableAppointments[index];
                    return ListTile(
                      leading: const Icon(Icons.edit, color: Colors.orange),
                      title: Text(
                        'Dr. ${appointment.doctorName}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_formatDate(appointment.appointmentDate)} - ${appointment.timeSlot}\n'
                        'Estado: ${appointment.statusText}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _editAppointment(appointment, user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /**
   * Abre la página de edición de una cita
   * @param appointment - Cita a editar
   * @param user - Usuario paciente
   */
  void _editAppointment(AppointmentModel appointment, UserModel user) async {
    // Obtener el doctor de la cita
    try {
      final doctorDoc = await _firestore
          .collection('usuarios')
          .doc(appointment.doctorId)
          .get();
      
      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data()!;
        final doctor = UserModel.fromMap(doctorData);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAppointmentPage(
              patient: user,
              preselectedDoctor: doctor,
              editingAppointment: appointment,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontró información del doctor")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al editar cita: $e")),
      );
    }
  }

}
