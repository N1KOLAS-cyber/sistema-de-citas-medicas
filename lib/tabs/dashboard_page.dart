import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'appointments_page.dart';
import 'doctors_page.dart';
import 'profile_page.dart';

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
              
              if (widget.user.isDoctor) ...[
                // Acciones para doctores
                _buildActionCard(
                  "Ver Mis Citas",
                  "Gestiona tus citas programadas",
                  Icons.calendar_month,
                  Colors.green,
                  () => setState(() => _currentIndex = 1),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  "Mi Perfil",
                  "Actualiza tu información profesional",
                  Icons.person,
                  Colors.purple,
                  () => setState(() => _currentIndex = 3),
                ),
              ] else ...[
                // Acciones para pacientes
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
                _buildActionCard(
                  "Mi Perfil",
                  "Actualiza tu información personal",
                  Icons.person,
                  Colors.purple,
                  () => setState(() => _currentIndex = 3),
                ),
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
      floatingActionButton: widget.user.isDoctor
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implementar crear nueva cita para doctores
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Función en desarrollo"),
                  ),
                );
              },
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
