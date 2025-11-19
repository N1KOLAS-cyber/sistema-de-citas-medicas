/**
 * HOME PAGE - PÁGINA PRINCIPAL DEL SISTEMA DE CITAS MÉDICAS
 * 
 * Este archivo contiene la página principal (home) del sistema de citas médicas.
 * Es el dashboard central que se muestra después del login y funciona como el
 * punto de entrada principal para usuarios y doctores.
 * 
 * FUNCIONALIDADES PRINCIPALES:
 * - Dashboard personalizado según el tipo de usuario (paciente/doctor)
 * - Navegación entre diferentes secciones (Citas, Doctores, Perfil)
 * - Acciones rápidas específicas por rol
 * - Consejos médicos interactivos
 * - Estadísticas para doctores
 * - Botón flotante contextual
 * 
 * ESTRUCTURA:
 * - Header con saludo personalizado
 * - Estadísticas (solo para doctores)
 * - Acciones rápidas por rol
 * - Consejos médicos
 * - Navegación inferior con tabs
 * 
 * VISUALIZACIÓN: Página principal con diseño moderno, gradientes,
 * tarjetas informativas y navegación intuitiva.
 */

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../services/advice_service.dart';
import 'appointments_page.dart';
import 'doctors_page.dart';
import 'profile_page.dart';
import 'doctor_availability_page.dart';
import 'create_appointment_page.dart';
import 'admin_tools_page.dart';
import 'doctor_appointments_page.dart';
import '../widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _randomAdvice = 'La prevención es la mejor medicina. Realiza chequeos médicos regulares.';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> _pages = [];
  
  @override
  void initState() {
    super.initState();
    // Inicializar las páginas del tab navigation
    _pages.addAll([
      _buildHomePage(), // Página principal personalizada
      const AppointmentsPage(), // Página de citas
      const DoctorsPage(), // Página de doctores
      ProfilePage(user: widget.user), // Página de perfil del usuario
    ]);
    // Cargar consejo después de que el widget está montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRandomAdvice();
      _refreshAdvicePeriodically();
    });
  }

  /**
   * Construye la página principal personalizada del dashboard
   * Muestra contenido diferente según el tipo de usuario (doctor/paciente)
   * @return Widget - Scaffold con el contenido principal
   */
  Widget _buildHomePage() {
    return Scaffold(
      drawer: AppDrawer(user: widget.user),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) => Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.indigo, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Abrir menú lateral',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Header con saludo personalizado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.indigo, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Hola, ${widget.user.name}!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.isDoctor 
                          ? "Panel de Doctor - ${widget.user.specialty}"
                          : "Bienvenido al Sistema de Citas Médicas",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Widget de Consejo Aleatorio
              _buildRandomAdviceCard(),
              const SizedBox(height: 24),

              // Estadísticas de Citas (para pacientes y doctores)
              widget.user.isDoctor
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Estadísticas",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "Citas Totales",
                                "${widget.user.totalAppointments ?? 0}",
                                Icons.calendar_today,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                "Calificación",
                                "${widget.user.rating?.toStringAsFixed(1) ?? '0.0'} ⭐",
                                Icons.star,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDoctorAppointmentStats(),
                        const SizedBox(height: 24),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mis Citas",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAppointmentStats(),
                        const SizedBox(height: 24),
                      ],
                    ),

              // Acciones rápidas
              const Text(
                "Acciones Rápidas",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón de Admin Tools (solo para administradores)
              if (widget.user.email.contains('admin')) ...[
                _buildActionCard(
                  "⚙️ Herramientas Admin",
                  "Crear horarios masivos y más utilidades",
                  Icons.admin_panel_settings,
                  Colors.deepOrange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminToolsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Verificar rol del usuario (prioridad: role > isDoctor)
              if (widget.user.role == 'Médico' || 
                  (widget.user.role == null && widget.user.isDoctor)) ...[
                // Acciones para médicos
                _buildActionCard(
                  "Gestionar Citas",
                  "Revisa y aprueba citas pendientes",
                  Icons.calendar_today,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorAppointmentsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  "Gestionar Horarios",
                  "Configura tu disponibilidad de consultas",
                  Icons.access_time,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorAvailabilityPage(doctor: widget.user),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  "Ver Mis Citas",
                  "Gestiona tus citas programadas",
                  Icons.calendar_month,
                  Colors.green,
                  () => setState(() => _currentIndex = 1),
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Acciones para pacientes
                _buildActionCard(
                  "Agregar Cita",
                  "Reserva una consulta con un especialista",
                  Icons.add_circle,
                  Colors.indigo,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateAppointmentPage(patient: widget.user),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  "Buscar Doctores",
                  "Encuentra especialistas cerca de ti",
                  Icons.search,
                  Colors.blue,
                  () => setState(() => _currentIndex = 2),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  "Mis Citas",
                  "Revisa tus citas programadas",
                  Icons.calendar_month,
                  Colors.green,
                  () => setState(() => _currentIndex = 1),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /**
   * Construye una tarjeta de estadísticas para doctores
   * @param title - Título de la estadística
   * @param value - Valor numérico a mostrar
   * @param icon - Icono representativo
   * @param color - Color del tema de la tarjeta
   * @return Widget - Tarjeta con estadística
   */
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /**
   * Carga un consejo médico aleatorio desde Firestore
   */
  void _loadRandomAdvice() async {
    if (!mounted) return;
    
    try {
      final advice = await AdviceService.getRandomAdvice();
      if (mounted && advice.isNotEmpty) {
        setState(() {
          _randomAdvice = advice;
        });
      }
    } catch (e) {
      // Si hay algún error, mostrar un consejo por defecto aleatorio
      if (mounted) {
        final defaultAdvices = [
          'La prevención es la mejor medicina. Realiza chequeos médicos regulares.',
          'Mantén un estilo de vida saludable con ejercicio regular y una dieta balanceada.',
          'Cuida tu salud visitando al médico regularmente.',
          'Duerme bien, come saludable y haz ejercicio para mantenerte sano.',
          'El agua es esencial para tu organismo, bebe al menos 8 vasos al día.',
        ];
        final random = Random();
        setState(() {
          _randomAdvice = defaultAdvices[random.nextInt(defaultAdvices.length)];
        });
      }
    }
  }

  /**
   * Muestra un diálogo para editar citas existentes
   */
  void _showEditAppointmentDialog() async {
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
        // Si no hay citas editables, mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No tienes citas editables en este momento"),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Mostrar diálogo con lista de citas para editar
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Editar Cita"),
          content: SizedBox(
            width: double.maxFinite,
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
                    '${_formatAppointmentDate(appointment.appointmentDate)} - ${appointment.timeSlot}\n'
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
   * Formatea una fecha de cita para mostrar
   */
  String _formatAppointmentDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  /**
   * Abre la página de edición de una cita
   */
  void _editAppointment(AppointmentModel appointment, UserModel user) async {
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
  
  /**
   * Refresca el consejo periódicamente cada 30 segundos
   */
  void _refreshAdvicePeriodically() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _currentIndex == 0) {
        _loadRandomAdvice();
        _refreshAdvicePeriodically();
      }
    });
  }

  /**
   * Construye la tarjeta de consejo médico aleatorio
   * Muestra un consejo diferente cada vez que se carga la página
   * @return Widget - Tarjeta con consejo médico aleatorio
   */
  Widget _buildRandomAdviceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.teal.shade50,
      child: InkWell(
        onTap: _loadRandomAdvice,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lightbulb, color: Colors.teal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Consejo del Día',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: Colors.teal),
                    onPressed: _loadRandomAdvice,
                    tooltip: 'Actualizar consejo',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _randomAdvice,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * Construye los widgets de estadísticas de citas para pacientes
   * @return Widget - Tarjetas con estadísticas de citas
   */
  Widget _buildAppointmentStats() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('citas')
          .where('patientId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int totalCitas = 0;
        int pendientesPorConfirmar = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final appointments = snapshot.data!.docs;
          totalCitas = appointments.length;
          
          final now = DateTime.now();
          pendientesPorConfirmar = appointments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String?;
            final appointmentDate = data['appointmentDate'];
            
            DateTime date;
            if (appointmentDate is int) {
              date = DateTime.fromMillisecondsSinceEpoch(appointmentDate);
            } else if (appointmentDate is DateTime) {
              date = appointmentDate;
            } else {
              try {
                date = (appointmentDate as dynamic).toDate();
              } catch (e) {
                return false;
              }
            }
            
            // Contar citas pendientes o confirmadas que sean futuras
            return (status == 'pending' || status == 'confirmed') && 
                   date.isAfter(now.subtract(const Duration(seconds: 1)));
          }).length;
        }

        // Mostrar indicador de carga mientras se obtienen los datos
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total Citas",
                  "...",
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  "Pendientes",
                  "...",
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total Citas",
                "$totalCitas",
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Pendientes",
                "$pendientesPorConfirmar",
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  /**
   * Construye los widgets de estadísticas de citas para doctores
   * Muestra las citas pendientes que deben aceptar
   * @return Widget - Tarjetas con estadísticas de citas
   */
  Widget _buildDoctorAppointmentStats() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('citas')
          .where('doctorId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int pendientesAceptar = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final appointments = snapshot.data!.docs;
          
          final now = DateTime.now();
          pendientesAceptar = appointments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String?;
            final appointmentDate = data['appointmentDate'];
            
            DateTime date;
            if (appointmentDate is int) {
              date = DateTime.fromMillisecondsSinceEpoch(appointmentDate);
            } else if (appointmentDate is DateTime) {
              date = appointmentDate;
            } else {
              try {
                date = (appointmentDate as dynamic).toDate();
              } catch (e) {
                return false;
              }
            }
            
            // Contar solo citas pendientes que sean futuras (que el doctor debe aceptar)
            return status == 'pending' && 
                   date.isAfter(now.subtract(const Duration(seconds: 1)));
          }).length;
        }

        // Mostrar indicador de carga mientras se obtienen los datos
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Citas Pendientes",
                  "...",
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Citas Pendientes",
                "$pendientesAceptar",
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  /**
   * Construye una tarjeta de acción rápida
   * @param title - Título de la acción
   * @param subtitle - Descripción de la acción
   * @param icon - Icono representativo
   * @param color - Color del tema
   * @param onTap - Función a ejecutar al tocar
   * @return Widget - Tarjeta de acción
   */
  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(user: widget.user),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Doctores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 && !widget.user.isDoctor
          ? FloatingActionButton.extended(
              onPressed: _showEditAppointmentDialog,
              backgroundColor: Colors.indigo,
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
              label: const Text(
                'Editar Cita',
                style: TextStyle(color: Colors.white),
              ),
            )
          : _currentIndex == 0 && widget.user.isDoctor
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorAvailabilityPage(doctor: widget.user),
                      ),
                    );
                  },
                  backgroundColor: Colors.indigo,
                  icon: const Icon(
                    Icons.access_time,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Horarios',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : null,
    );
  }
}