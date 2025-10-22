import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'appointments_page.dart';
import 'doctors_page.dart';
import 'profile_page.dart';
import 'doctor_availability_page.dart';
import 'create_appointment_page.dart';
import 'admin_tools_page.dart';

class DashboardPage extends StatefulWidget {
  final UserModel user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _buildHomePage(),
      const AppointmentsPage(),
      const DoctorsPage(),
      ProfilePage(user: widget.user),
    ]);
  }

  Widget _buildHomePage() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con saludo
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

              // Estadísticas rápidas
              if (widget.user.isDoctor) ...[
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
                const SizedBox(height: 24),
              ],

              // Acciones rápidas
              const Text(
                "Acciones Rápidas",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón de Admin Tools (para todos, pero útil para doctores)
              if (widget.user.email.contains('admin') || widget.user.isDoctor) ...[
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

              // Widget de Consejos Médicos (para todos)
              _buildMedicalAdviceCard(),
              const SizedBox(height: 12),

              if (widget.user.isDoctor) ...[
                // Acciones para doctores
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
                  "Agendar Cita",
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

  Widget _buildMedicalAdviceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.teal.shade50,
      child: InkWell(
        onTap: _showMedicalAdvice,
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
                    child: const Icon(Icons.tips_and_updates, color: Colors.teal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consejos Médicos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '¿No sabes qué médico consultar?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.teal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalAdvice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_hospital, color: Colors.teal),
            SizedBox(width: 8),
            Text('Consejos Médicos'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🤔 ¿No sabes qué médico consultar?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              
              _buildAdviceItem(
                emoji: '🌮',
                problem: 'Si comiste tacos de la esquina y te cayeron mal',
                advice: 'Ve con un Médico General',
                specialty: 'Medicina General',
              ),
              
              _buildAdviceItem(
                emoji: '🐸',
                problem: 'Si te besó el sapo y ahora tienes calentura',
                advice: 'Ve con un Médico General o Infectólogo',
                specialty: 'Medicina General',
              ),
              
              _buildAdviceItem(
                emoji: '❤️',
                problem: 'Si sientes que tu corazón late diferente',
                advice: 'Ve con un Cardiólogo',
                specialty: 'Cardiología',
              ),
              
              _buildAdviceItem(
                emoji: '👶',
                problem: 'Si tu bebé tiene fiebre o malestar',
                advice: 'Ve con un Pediatra',
                specialty: 'Pediatría',
              ),
              
              _buildAdviceItem(
                emoji: '👁️',
                problem: 'Si ves borroso o te duelen los ojos',
                advice: 'Ve con un Oftalmólogo',
                specialty: 'Oftalmología',
              ),
              
              _buildAdviceItem(
                emoji: '🦴',
                problem: 'Si te duelen los huesos o articulaciones',
                advice: 'Ve con un Ortopedista',
                specialty: 'Ortopedia',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2); // Ir a Doctores
            },
            child: const Text('Ver Doctores'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceItem({
    required String emoji,
    required String problem,
    required String advice,
    required String specialty,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        problem,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '→ $advice',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Doctores',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                if (widget.user.isDoctor) {
                  // Para doctores: gestionar horarios
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorAvailabilityPage(doctor: widget.user),
                    ),
                  );
                } else {
                  // Para pacientes: agendar cita
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAppointmentPage(patient: widget.user),
                    ),
                  );
                }
              },
              backgroundColor: Colors.indigo,
              icon: Icon(
                widget.user.isDoctor ? Icons.access_time : Icons.add,
                color: Colors.white,
              ),
              label: Text(
                widget.user.isDoctor ? 'Horarios' : 'Nueva Cita',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
