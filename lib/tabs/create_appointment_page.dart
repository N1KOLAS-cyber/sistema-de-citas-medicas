/**
 * CREATE APPOINTMENT PAGE - PÁGINA DE CREACIÓN DE CITAS
 * 
 * Este archivo contiene la página para que los pacientes creen nuevas citas médicas.
 * Utiliza un proceso paso a paso (stepper) para guiar al usuario.
 * 
 * FUNCIONALIDADES:
 * - Selección de doctor (con doctor preseleccionado opcional)
 * - Selección de fecha con calendario
 * - Selección de horario disponible
 * - Detalles de la cita (tipo, síntomas, notas)
 * - Creación y confirmación de la cita
 * - Validación de disponibilidad en tiempo real
 * 
 * ESTRUCTURA:
 * - Stepper con 4 pasos: Doctor, Fecha, Horario, Detalles
 * - Validación en cada paso
 * - Resumen de la cita antes de confirmar
 * - Manejo de errores y estados de carga
 * 
 * VISUALIZACIÓN: Página con stepper intuitivo, validaciones claras,
 * información de debug y confirmación visual del proceso.
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/doctor_availability_model.dart';
import '../services/firestore_service.dart';

/// Página para que los pacientes creen nuevas citas médicas
class CreateAppointmentPage extends StatefulWidget {
  final UserModel patient;
  final UserModel? preselectedDoctor; // Doctor preseleccionado (opcional)
  final AppointmentModel? editingAppointment; // Cita a editar (opcional)

  const CreateAppointmentPage({
    super.key,
    required this.patient,
    this.preselectedDoctor,
    this.editingAppointment,
  });

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  UserModel? selectedDoctor;
  DateTime? selectedDate;
  DoctorAvailabilityModel? selectedSlot;
  AppointmentType selectedType = AppointmentType.consultation;
  
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  bool _loading = false;
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedDoctor != null) {
      selectedDoctor = widget.preselectedDoctor;
      currentStep = 1; // Ir directamente a selección de fecha
    }
    
    // Si estamos editando una cita, cargar los datos
    if (widget.editingAppointment != null) {
      final appointment = widget.editingAppointment!;
      selectedType = appointment.type;
      symptomsController.text = appointment.symptoms ?? '';
      notesController.text = appointment.notes ?? '';
      // Los otros campos se cargarán cuando se seleccione el doctor/fecha
    }
  }

  @override
  void dispose() {
    symptomsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingAppointment != null ? "Editar Cita" : "Agendar Cita"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creando tu cita...'),
                ],
              ),
            )
          : Stepper(
        currentStep: currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (currentStep < 3)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continuar'),
                  ),
                if (currentStep == 3)
                  ElevatedButton(
                    onPressed: widget.editingAppointment != null 
                        ? _updateAppointment 
                        : _createAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(widget.editingAppointment != null 
                        ? 'Actualizar Cita' 
                        : 'Confirmar Cita'),
                  ),
                const SizedBox(width: 8),
                if (currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Atrás'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Seleccionar Doctor'),
            content: _buildDoctorSelection(),
            isActive: currentStep >= 0,
            state: currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Seleccionar Fecha'),
            content: _buildDateSelection(),
            isActive: currentStep >= 1,
            state: currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Seleccionar Horario'),
            content: _buildTimeSlotSelection(),
            isActive: currentStep >= 2,
            state: currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Detalles de la Cita'),
            content: _buildAppointmentDetails(),
            isActive: currentStep >= 3,
            state: currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  /**
   * Construye el widget de selección de doctor
   * @return Widget - Lista de doctores disponibles o doctor preseleccionado
   */
  Widget _buildDoctorSelection() {
    if (widget.preselectedDoctor != null) {
      return _buildDoctorCard(widget.preselectedDoctor!);
    }

    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService.getDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        List<UserModel> doctors = snapshot.data ?? [];

        if (doctors.isEmpty) {
          return const Center(
            child: Text('No hay doctores disponibles'),
          );
        }

        return Column(
          children: doctors.map((doctor) {
            bool isSelected = selectedDoctor?.id == doctor.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                elevation: isSelected ? 8 : 2,
                color: isSelected ? Colors.indigo.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.indigo : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.indigo : Colors.grey,
                    child: Text(
                      doctor.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    'Dr. ${doctor.name}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.indigo : Colors.black,
                    ),
                  ),
                  subtitle: Text(doctor.specialty ?? 'Medicina General'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      selectedDoctor = doctor;
                    });
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /**
   * Construye la tarjeta de información de un doctor
   * @param doctor - Doctor a mostrar
   * @return Widget - Tarjeta con información del doctor
   */
  Widget _buildDoctorCard(UserModel doctor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.indigo,
              child: Text(
                doctor.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${doctor.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(doctor.specialty ?? 'Medicina General'),
                  if (doctor.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        Text(' ${doctor.rating!.toStringAsFixed(1)}'),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Construye el widget de selección de fecha
   * @return Widget - Selector de fecha con calendario
   */
  Widget _buildDateSelection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _selectDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            selectedDate == null
                ? 'Seleccionar Fecha'
                : _formatDate(selectedDate!),
          ),
        ),
        if (selectedDate != null) ...[
          const SizedBox(height: 16),
          Text(
            _getDayOfWeek(selectedDate!),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  /**
   * Construye el widget de selección de horario
   * @return Widget - Lista de horarios disponibles del doctor
   */
  Widget _buildTimeSlotSelection() {
    if (selectedDoctor == null || selectedDate == null) {
      return const Text('Primero selecciona un doctor y una fecha');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de debug
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buscando horarios de:',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                'Dr. ${selectedDoctor!.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Fecha: ${_formatDate(selectedDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<List<DoctorAvailabilityModel>>(
          stream: FirestoreService.getAvailableSlots(
            selectedDoctor!.id,
            selectedDate!,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando horarios disponibles...'),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Intenta seleccionar otra fecha',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            List<DoctorAvailabilityModel> slots = snapshot.data ?? [];

            if (slots.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay horarios disponibles para esta fecha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'El doctor no ha configurado horarios para este día.\n'
                        'Por favor, selecciona otra fecha.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            currentStep = 1; // Volver a selección de fecha
                            selectedSlot = null;
                          });
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Cambiar Fecha'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Mostrar horarios disponibles
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ ${slots.length} horarios disponibles',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots.map((slot) {
                    bool isSelected = selectedSlot?.id == slot.id;
                    return ChoiceChip(
                      label: Text(
                        slot.timeSlot,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedSlot = selected ? slot : null;
                        });
                      },
                      selectedColor: Colors.indigo,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /**
   * Construye el widget de detalles de la cita
   * @return Widget - Formulario con detalles de la cita
   */
  Widget _buildAppointmentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen de la cita
        Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de la Cita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildSummaryRow('Doctor', 'Dr. ${selectedDoctor?.name ?? "N/A"}'),
                _buildSummaryRow('Especialidad', selectedDoctor?.specialty ?? "N/A"),
                _buildSummaryRow('Fecha', selectedDate != null ? _formatDate(selectedDate!) : "N/A"),
                _buildSummaryRow('Horario', selectedSlot?.timeSlot ?? "N/A"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tipo de cita
        const Text(
          'Tipo de Consulta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AppointmentType>(
          value: selectedType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services),
          ),
          items: AppointmentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getTypeText(type)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedType = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Síntomas
        const Text(
          'Síntomas (opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: symptomsController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Describe tus síntomas...',
            prefixIcon: Icon(Icons.sick),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Notas adicionales
        const Text(
          'Notas Adicionales (opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Información adicional...',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  /**
   * Construye una fila de resumen de la cita
   * @param label - Etiqueta del campo
   * @param value - Valor del campo
   * @return Widget - Fila de resumen
   */
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
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
   * Maneja la navegación al siguiente paso del stepper
   * Valida que se haya completado el paso actual
   */
  void _onStepContinue() {
    if (currentStep == 0 && selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un doctor')),
      );
      return;
    }

    if (currentStep == 1 && selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una fecha')),
      );
      return;
    }

    if (currentStep == 2 && selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un horario')),
      );
      return;
    }

    setState(() {
      if (currentStep < 3) {
        currentStep += 1;
      }
    });
  }

  /**
   * Maneja la navegación al paso anterior del stepper
   */
  void _onStepCancel() {
    setState(() {
      if (currentStep > 0) {
        currentStep -= 1;
      }
    });
  }

  /**
   * Abre el selector de fecha y actualiza la fecha seleccionada
   */
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedSlot = null; // Reset slot selection
      });
    }
  }

  /**
   * Actualiza una cita médica existente
   * Valida disponibilidad y marca el nuevo horario como ocupado
   */
  Future<void> _updateAppointment() async {
    if (widget.editingAppointment == null) return;
    if (selectedDoctor == null || selectedDate == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Si cambió el horario, verificar disponibilidad
      if (selectedSlot!.id != widget.editingAppointment!.id) {
        bool isStillAvailable = await FirestoreService.isTimeSlotAvailable(
          selectedDoctor!.id,
          selectedSlot!.startTime,
          selectedSlot!.endTime,
        );

        if (!isStillAvailable) {
          throw Exception('Este horario ya no está disponible. Por favor selecciona otro.');
        }

        // Liberar el horario anterior si existía
        // (Aquí deberías buscar el availabilityId asociado a la cita original)
      }

      // Actualizar la cita
      AppointmentModel updatedAppointment = widget.editingAppointment!.copyWith(
        doctorId: selectedDoctor!.id,
        doctorName: selectedDoctor!.name,
        specialty: selectedDoctor!.specialty ?? 'Medicina General',
        appointmentDate: selectedSlot!.date,
        timeSlot: selectedSlot!.timeSlot,
        type: selectedType,
        symptoms: symptomsController.text.trim().isNotEmpty 
            ? symptomsController.text.trim() 
            : null,
        notes: notesController.text.trim().isNotEmpty 
            ? notesController.text.trim() 
            : null,
        updatedAt: DateTime.now(),
      );

      await FirestoreService.updateAppointment(updatedAppointment);

      setState(() => _loading = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 8),
                Text('¡Cita Actualizada!'),
              ],
            ),
            content: const Text(
              'Tu cita ha sido actualizada exitosamente.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(true); // Volver a página anterior
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Crea la cita médica con todos los datos seleccionados
   * Valida disponibilidad y marca el horario como ocupado
   */
  Future<void> _createAppointment() async {
    if (selectedDoctor == null || selectedDate == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Verificar que el horario sigue disponible
      bool isStillAvailable = await FirestoreService.isTimeSlotAvailable(
        selectedDoctor!.id,
        selectedSlot!.startTime,
        selectedSlot!.endTime,
      );

      if (!isStillAvailable) {
        throw Exception('Este horario ya no está disponible. Por favor selecciona otro.');
      }

      // Crear la cita
      String appointmentId = FirebaseFirestore.instance
          .collection('citas')
          .doc()
          .id;

      AppointmentModel appointment = AppointmentModel(
        id: appointmentId,
        patientId: widget.patient.id,
        doctorId: selectedDoctor!.id,
        patientName: widget.patient.name,
        doctorName: selectedDoctor!.name,
        specialty: selectedDoctor!.specialty ?? 'Medicina General',
        appointmentDate: selectedSlot!.date,
        timeSlot: selectedSlot!.timeSlot,
        status: AppointmentStatus.pending,
        type: selectedType,
        symptoms: symptomsController.text.trim().isNotEmpty 
            ? symptomsController.text.trim() 
            : null,
        notes: notesController.text.trim().isNotEmpty 
            ? notesController.text.trim() 
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService.createAppointment(appointment);

      // Marcar el horario como ocupado
      await FirestoreService.markSlotAsUnavailable(
        selectedSlot!.id,
        appointmentId,
      );

      setState(() => _loading = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 8),
                Text('¡Cita Creada!'),
              ],
            ),
            content: const Text(
              'Tu cita ha sido agendada exitosamente.\n\n'
              'Recibirás una confirmación cuando el doctor acepte la cita.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(true); // Volver a página anterior
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Formatea una fecha para mostrar en la interfaz
   * @param date - Fecha a formatear
   * @return String - Fecha formateada en español
   */
  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  /**
   * Obtiene el día de la semana en español
   * @param date - Fecha de la cual obtener el día
   * @return String - Día de la semana en español
   */
  String _getDayOfWeek(DateTime date) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[date.weekday - 1];
  }

  /**
   * Obtiene el texto legible del tipo de cita
   * @param type - Tipo de cita
   * @return String - Texto del tipo en español
   */
  String _getTypeText(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return 'Consulta General';
      case AppointmentType.followUp:
        return 'Seguimiento';
      case AppointmentType.emergency:
        return 'Emergencia';
      case AppointmentType.routine:
        return 'Chequeo de Rutina';
    }
  }
}

