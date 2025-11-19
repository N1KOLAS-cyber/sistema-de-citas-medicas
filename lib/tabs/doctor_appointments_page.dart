//
// DOCTOR APPOINTMENTS PAGE - PÁGINA DE CITAS PARA DOCTORES
//
// Este archivo contiene la página que permite a los doctores ver y gestionar
// las citas que han solicitado los pacientes.
//
// FUNCIONALIDADES:
// - Lista de citas pendientes de aprobación
// - Aprobación o rechazo de citas
// - Visualización de detalles del paciente
// - Filtros por estado de cita
// - Notificaciones de nuevas solicitudes
//
// ESTRUCTURA:
// - AppBar con filtros y acciones
// - Lista de citas con información detallada
// - Botones de aprobación/rechazo
// - Diálogos de confirmación
//
// VISUALIZACIÓN: Página con diseño de tarjetas, filtros intuitivos,
// información clara de cada cita y botones de acción contextuales.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'Pendientes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Citas Médicas"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Menú de filtros
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Pendientes', child: Text('Pendientes')),
              const PopupMenuItem(value: 'Confirmadas', child: Text('Confirmadas')),
              const PopupMenuItem(value: 'Todas', child: Text('Todas')),
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
                    'No hay citas disponibles',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Las nuevas solicitudes aparecerán aquí',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          List<AppointmentModel> appointments = snapshot.data!.docs
              .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Ordenar por fecha de cita (más recientes primero)
          appointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

          // Filtrar citas según el filtro seleccionado
          appointments = _filterAppointments(appointments);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(appointments[index]);
            },
          );
        },
      ),
    );
  }

  ///
  /// Obtiene el stream de citas del doctor actual desde Firestore.
  Stream<QuerySnapshot> _getAppointmentsStream() {
    User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      // Si no hay usuario autenticado, retornar stream vacío
      return _firestore
          .collection('citas')
          .where('doctorId', isEqualTo: 'no-user')
          .snapshots();
    }

    // Filtrar citas donde el usuario es doctor (sin ordenamiento para evitar índice)
    return _firestore
        .collection('citas')
        .where('doctorId', isEqualTo: currentUser.uid)
        .snapshots();
  }

  ///
  /// Filtra las citas según el filtro seleccionado y devuelve la lista resultante.
  List<AppointmentModel> _filterAppointments(List<AppointmentModel> appointments) {
    if (_selectedFilter == 'Pendientes') {
      return appointments.where((appointment) {
        return appointment.status == AppointmentStatus.pending;
      }).toList();
    } else if (_selectedFilter == 'Confirmadas') {
      return appointments.where((appointment) {
        return appointment.status == AppointmentStatus.confirmed;
      }).toList();
    }
    // Si es 'Todas', no filtrar nada
    return appointments;
  }

  ///
  /// Construye la tarjeta de información de una cita
  /// @param appointment - Modelo de la cita a mostrar
  /// @return Widget - Tarjeta con información de la cita
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                    // Mostrar quién canceló la cita si está cancelada
                    if (appointment.status == AppointmentStatus.cancelled && 
                        appointment.cancelledBy != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.cancelledBy == 'patient' 
                                  ? 'Cancelada por paciente'
                                  : 'Cancelada por ti',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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

            // Información del paciente
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.indigo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.patientName,
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

            // Síntomas si existen
            if (appointment.symptoms != null && appointment.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Síntomas reportados:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.symptoms!,
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                      "Notas del paciente:",
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

            // Botones de acción para citas pendientes
            if (appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectAppointment(appointment),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text("Rechazar"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveAppointment(appointment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Aprobar"),
                    ),
                  ),
                ],
              ),
            ] else if (appointment.status == AppointmentStatus.confirmed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewPatientDetails(appointment),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        side: const BorderSide(color: Colors.indigo),
                      ),
                      child: const Text("Ver Paciente"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _completeAppointment(appointment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Completar"),
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

  ///
  /// Obtiene el color correspondiente al estado de una cita
  /// @param status - Estado de la cita
  /// @return Color - Color representativo del estado
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

  ///
  /// Formatea una fecha para mostrar en la interfaz
  /// @param date - Fecha a formatear
  /// @return String - Fecha formateada
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  ///
  /// Aprueba una cita pendiente
  /// @param appointment - Cita a aprobar
  void _approveAppointment(AppointmentModel appointment) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Aprobar Cita"),
        content: const Text("¿Estás seguro de que quieres aprobar esta cita?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await _updateAppointmentStatus(appointment.id, AppointmentStatus.confirmed);
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text("Cita aprobada exitosamente"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text("Error al aprobar cita: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Aprobar"),
          ),
        ],
      ),
    );
  }

  ///
  /// Rechaza una cita pendiente
  /// @param appointment - Cita a rechazar
  void _rejectAppointment(AppointmentModel appointment) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Rechazar Cita"),
        content: const Text("¿Estás seguro de que quieres rechazar esta cita?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await _updateAppointmentStatus(
                  appointment.id, 
                  AppointmentStatus.cancelled,
                  cancelledBy: 'doctor',
                );
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text("Cita rechazada"),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text("Error al rechazar cita: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Rechazar"),
          ),
        ],
      ),
    );
  }

  ///
  /// Actualiza el estado de una cita en Firestore
  /// @param appointmentId - ID de la cita
  /// @param newStatus - Nuevo estado de la cita
  /// @param cancelledBy - Opcional: quién canceló la cita ('patient' o 'doctor')
  Future<void> _updateAppointmentStatus(
    String appointmentId, 
    AppointmentStatus newStatus, {
    String? cancelledBy,
  }) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Preparar los datos a actualizar
      final Map<String, dynamic> updateData = {
        'status': newStatus.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Si se está cancelando, agregar información de quién canceló
      if (newStatus == AppointmentStatus.cancelled && cancelledBy != null) {
        updateData['cancelledBy'] = cancelledBy;
      }

      // Actualizar el estado en Firestore
      await _firestore.collection('citas').doc(appointmentId).update(updateData);

      // Cerrar indicador de carga
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      // Cerrar indicador de carga si hay error
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al actualizar cita: $e"),
          backgroundColor: Colors.red,
        ),
      );
      throw Exception('Error al actualizar cita: $e');
    }
  }

  ///
  /// Muestra los detalles del paciente
  /// @param appointment - Cita de la cual mostrar detalles del paciente
  void _viewPatientDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Detalles del Paciente"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow("Nombre:", appointment.patientName),
              _buildDetailRow("Especialidad:", appointment.specialty),
              _buildDetailRow("Fecha:", _formatDate(appointment.appointmentDate)),
              _buildDetailRow("Hora:", appointment.timeSlot),
              _buildDetailRow("Estado:", appointment.statusText),
              _buildDetailRow("Tipo:", appointment.typeText),
              if (appointment.notes != null)
                _buildDetailRow("Notas:", appointment.notes!),
              if (appointment.symptoms != null)
                _buildDetailRow("Síntomas:", appointment.symptoms!),
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

  ///
  /// Marca una cita como completada
  /// @param appointment - Cita a completar
  void _completeAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Completar Cita"),
        content: const Text("¿Has completado la consulta con este paciente?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _updateAppointmentStatus(appointment.id, AppointmentStatus.completed);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cita marcada como completada"),
                    backgroundColor: Colors.blue,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error al completar cita: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Completar"),
          ),
        ],
      ),
    );
  }

  ///
  /// Construye una fila de detalle para mostrar información
  /// @param label - Etiqueta del campo
  /// @param value - Valor del campo
  /// @return Widget - Fila de detalle
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
}
