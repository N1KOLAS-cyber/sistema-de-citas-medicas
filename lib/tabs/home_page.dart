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

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _randomAdvice = 'Cargando consejo...';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> _pages = [];
  
  @override
  void initState() {
    super.initState();
    _loadRandomAdvice();
    _refreshAdvicePeriodically();
    // Inicializar las páginas del tab navigation
    _pages.addAll([
      _buildHomePage(), // Página principal personalizada
      const AppointmentsPage(), // Página de citas
      const DoctorsPage(), // Página de doctores
      ProfilePage(user: widget.user), // Página de perfil del usuario
    ]);
  }

  /**
   * Construye la página principal personalizada del dashboard
   * Muestra contenido diferente según el tipo de usuario (doctor/paciente)
   * @return Widget - Scaffold con el contenido principal
   */
  Widget _buildHomePage() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // Widget de Consejo Aleatorio
              _buildRandomAdviceCard(),
              const SizedBox(height: 24),

              // Estadísticas de Citas (solo para pacientes)
              if (!widget.user.isDoctor) ...[
                _buildAppointmentStats(),
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

              if (widget.user.isDoctor) ...[
                // Acciones para doctores
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
   * Construye la tarjeta de consejos médicos interactiva
   * Permite a los usuarios obtener orientación sobre qué especialista consultar
   * @return Widget - Tarjeta con consejos médicos
   */
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

  /**
   * Muestra un diálogo con consejos médicos detallados
   * Ayuda a los usuarios a decidir qué especialista consultar según sus síntomas
   */
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

  /**
   * Construye un elemento individual de consejo médico
   * @param emoji - Emoji representativo del problema
   * @param problem - Descripción del problema/síntoma
   * @param advice - Consejo médico específico
   * @param specialty - Especialidad médica recomendada
   * @return Widget - Elemento de consejo médico
   */
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
