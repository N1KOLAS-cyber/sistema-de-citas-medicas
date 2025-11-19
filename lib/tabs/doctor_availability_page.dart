import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/doctor_availability_model.dart';
import '../services/firestore_service.dart';
import '../utils/logger.dart';

/// Página para que los doctores gestionen su disponibilidad de horarios
class DoctorAvailabilityPage extends StatefulWidget {
  final UserModel doctor;

  const DoctorAvailabilityPage({super.key, required this.doctor});

  @override
  State<DoctorAvailabilityPage> createState() => _DoctorAvailabilityPageState();
}

class _DoctorAvailabilityPageState extends State<DoctorAvailabilityPage> {
  DateTime selectedDate = DateTime.now();
  bool _loading = false;

  // Horarios estándar (9am - 5pm, cada hora)
  final List<Map<String, int>> standardHours = [
    {'hour': 9, 'minute': 0},
    {'hour': 10, 'minute': 0},
    {'hour': 11, 'minute': 0},
    {'hour': 12, 'minute': 0},
    {'hour': 13, 'minute': 0},
    {'hour': 14, 'minute': 0},
    {'hour': 15, 'minute': 0},
    {'hour': 16, 'minute': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Disponibilidad"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
            tooltip: 'Seleccionar fecha',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header con la fecha seleccionada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: Column(
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Text(
                  _getDayOfWeek(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Lista de horarios disponibles para la fecha seleccionada
          Expanded(
            child: StreamBuilder<List<DoctorAvailabilityModel>>(
              stream: FirestoreService.getAvailableSlots(
                widget.doctor.id,
                selectedDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                List<DoctorAvailabilityModel> availableSlots = snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Horarios del día',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Row(
                            children: [
                              // Botón para eliminar todos los horarios del día
                              if (availableSlots.isNotEmpty)
                                IconButton(
                                  onPressed: () => _deleteAllSlotsForDate(availableSlots),
                                  icon: const Icon(Icons.delete_sweep),
                                  color: Colors.red,
                                  tooltip: 'Eliminar todos los horarios',
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _createStandardSchedule,
                                icon: const Icon(Icons.add),
                                label: const Text('Crear Horarios'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (availableSlots.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay horarios disponibles para esta fecha',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Crea horarios usando el botón "Crear Horarios"',
                                  style: TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: availableSlots.length,
                          itemBuilder: (context, index) {
                            return _buildAvailabilityCard(availableSlots[index]);
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton(
              onPressed: _createCustomTimeSlot,
              backgroundColor: Colors.indigo,
              tooltip: 'Agregar horario personalizado',
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildAvailabilityCard(DoctorAvailabilityModel slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: slot.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            slot.isAvailable ? Icons.check_circle : Icons.cancel,
            color: slot.isAvailable ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          slot.timeSlot,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          slot.isAvailable ? 'Disponible' : 'Ocupado',
          style: TextStyle(
            color: slot.isAvailable ? Colors.green : Colors.red,
          ),
        ),
        trailing: slot.isAvailable
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteAvailability(slot),
              )
            : null,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _createStandardSchedule() async {
    // Mostrar confirmación
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Horarios Estándar'),
        content: Text(
          '¿Deseas crear horarios de 9:00 AM a 5:00 PM (cada hora) '
          'para el ${_formatDate(selectedDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    setState(() => _loading = true);

    try {
      // Crear lista de horarios
      List<Map<String, DateTime>> timeSlots = [];
      
      for (var hour in standardHours) {
        DateTime startTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour['hour']!,
          hour['minute']!,
        );
        
        DateTime endTime = startTime.add(const Duration(hours: 1));
        
        timeSlots.add({
          'start': startTime,
          'end': endTime,
        });
      }

      // Crear todos los horarios en batch
      await FirestoreService.createBulkAvailability(
        widget.doctor.id,
        widget.doctor.name,
        selectedDate,
        timeSlots,
      );

      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horarios creados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear horarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createCustomTimeSlot() async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 1) % 24,
        minute: startTime.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || endTime == null) return;

    setState(() => _loading = true);

    try {
      DateTime start = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      DateTime end = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        throw Exception('La hora de fin debe ser posterior a la hora de inicio');
      }

      String id = FirebaseFirestore.instance
          .collection('disponibilidad_medicos')
          .doc()
          .id;

      DoctorAvailabilityModel availability = DoctorAvailabilityModel(
        id: id,
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        date: selectedDate,
        timeSlot: '${_formatTime(start)} - ${_formatTime(end)}',
        startTime: start,
        endTime: end,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService.createAvailability(availability);

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAvailability(DoctorAvailabilityModel slot) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Horario'),
        content: Text('¿Deseas eliminar el horario ${slot.timeSlot}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      await FirestoreService.deleteAvailability(slot.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario eliminado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[date.weekday - 1];
  }

  String _formatTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Eliminar todos los horarios disponibles del día
  Future<void> _deleteAllSlotsForDate(List<DoctorAvailabilityModel> slots) async {
    // Filtrar solo los horarios disponibles (no ocupados)
    List<DoctorAvailabilityModel> availableSlots = 
        slots.where((slot) => slot.isAvailable).toList();

    if (availableSlots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay horarios disponibles para eliminar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Eliminar Todos los Horarios'),
          ],
        ),
        content: Text(
          '¿Deseas eliminar TODOS los ${availableSlots.length} horarios disponibles '
          'para el ${_formatDate(selectedDate)}?\n\n'
          'Los horarios ocupados con citas NO se eliminarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar Todos'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      int deletedCount = 0;
      int errorCount = 0;

      // Eliminar cada horario disponible
      for (var slot in availableSlots) {
        try {
          await FirestoreService.deleteAvailability(slot.id);
          deletedCount++;
        } catch (e) {
          errorCount++;
        logInfo('Error al eliminar horario ${slot.id}: $e');
        }
      }

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorCount == 0
                ? '✅ $deletedCount horarios eliminados exitosamente'
                : '⚠️ $deletedCount eliminados, $errorCount fallaron',
          ),
          backgroundColor: errorCount == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

