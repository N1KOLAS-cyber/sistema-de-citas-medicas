//
// APP DRAWER - SIDEBAR GLOBAL DE LA APLICACIÓN
//
// Drawer reutilizable que se muestra en todas las páginas principales de la app.
// Incluye navegación según el rol del usuario (Paciente/Médico).
//
// FUNCIONALIDADES:
// - Navegación principal según rol
// - Acceso al Dashboard (solo para médicos)
// - Acceso a perfil, citas, doctores
// - Cerrar sesión
// - Información del usuario actual

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../tabs/profile_page.dart';
import '../tabs/appointments_page.dart';
import '../tabs/doctors_page.dart';
import '../tabs/dashboard_page.dart';
import '../tabs/doctor_appointments_page.dart';
import '../tabs/doctor_availability_page.dart';
import '../tabs/create_appointment_page.dart';
import '../tabs/admin_tools_page.dart';
import '../tabs/simple_login_page.dart';
import '../tabs/home_page.dart';
import '../utils/logger.dart';

class AppDrawer extends StatelessWidget {
  final UserModel? user; // Opcional, si no se proporciona se obtiene de Firestore

  const AppDrawer({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final currentUser = snapshot.data;
        if (currentUser == null) {
          return const Drawer(
            child: Center(child: Text('Error al cargar usuario')),
          );
        }

        // Detección mejorada de médico - MÚLTIPLES FORMAS DE VERIFICAR
        bool isMedico = false;
        
        // Verificar por role (con diferentes variaciones)
        if (currentUser.role != null) {
          final roleLower = currentUser.role!.toLowerCase().trim();
          isMedico = roleLower == 'médico' || 
                     roleLower == 'medico' ||
                     roleLower == 'doctor' ||
                     roleLower == 'dr' ||
                     currentUser.role == 'Médico';
        }
        
        // Verificar por isDoctor
        if (!isMedico && currentUser.isDoctor == true) {
          isMedico = true;
        }
        
        // Verificar por email (admin siempre es médico)
        if (!isMedico && currentUser.email.toLowerCase().contains('admin')) {
          isMedico = true;
        }
        
        final bool isAdmin = currentUser.email.contains('admin');
        
        // Debug: imprimir información del usuario
        logInfo('═══════════════════════════════════════');
        logInfo('🔍 DEBUG AppDrawer - INFORMACIÓN DEL USUARIO');
        logInfo('═══════════════════════════════════════');
        logInfo('👤 Usuario: ${currentUser.name}');
        logInfo('📧 Email: ${currentUser.email}');
        logInfo('🏷️  Role: "${currentUser.role}" (tipo: ${currentUser.role.runtimeType})');
        logInfo('👨‍⚕️ isDoctor: ${currentUser.isDoctor} (tipo: ${currentUser.isDoctor.runtimeType})');
        logInfo('✅ isMedico (resultado): $isMedico');
        logInfo('═══════════════════════════════════════');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header del drawer con información del usuario
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              isMedico ? "Dr. ${currentUser.name}" : currentUser.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              currentUser.email,
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                isMedico ? Icons.medical_services : Icons.person,
                color: const Color(0xFF1976D2),
                size: 40,
              ),
            ),
          ),

          // Sección: Acciones Rápidas (replicando HomePage)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // Navegación común
          ListTile(
            leading: const Icon(Icons.home, color: Colors.indigo),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomePage(user: currentUser),
                ),
              );
            },
          ),

          // Sección para MÉDICOS (replicando HomePage)
          if (isMedico) ...[
            const Divider(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Panel Médico',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // Dashboard - Solo para médicos
            Container(
              color: Colors.blue.withValues(alpha: 0.05),
              child: ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.blue, size: 32),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                subtitle: const Text(
                  'Estadísticas y análisis médico',
                  style: TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                onTap: () {
                  logInfo('🔍 DEBUG - Navegando al Dashboard para: ${currentUser.name}');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardPage(user: currentUser),
                    ),
                  );
                },
              ),
            ),
            
            // Gestionar Citas (replicando HomePage)
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.green),
              title: const Text('Gestionar Citas'),
              subtitle: const Text('Revisa y aprueba citas pendientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorAppointmentsPage(),
                  ),
                );
              },
            ),
            
            // Gestionar Horarios (replicando HomePage)
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange),
              title: const Text('Gestionar Horarios'),
              subtitle: const Text('Configura tu disponibilidad de consultas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorAvailabilityPage(doctor: currentUser),
                  ),
                );
              },
            ),
            
            // Ver Mis Citas (replicando HomePage)
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.green),
              title: const Text('Ver Mis Citas'),
              subtitle: const Text('Gestiona tus citas programadas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentsPage(),
                  ),
                );
              },
            ),
          ],

          // Sección para PACIENTES (replicando HomePage)
          if (!isMedico) ...[
            // Agregar Cita (replicando HomePage)
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.indigo),
              title: const Text('Agregar Cita'),
              subtitle: const Text('Reserva una consulta con un especialista'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAppointmentPage(patient: currentUser),
                  ),
                );
              },
            ),
            
            // Buscar Doctores (replicando HomePage)
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text('Buscar Doctores'),
              subtitle: const Text('Encuentra especialistas cerca de ti'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorsPage(),
                  ),
                );
              },
            ),
            
            // Mis Citas (replicando HomePage)
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.green),
              title: const Text('Mis Citas'),
              subtitle: const Text('Revisa tus citas programadas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentsPage(),
                  ),
                );
              },
            ),
          ],

          // Sección de administración (replicando HomePage)
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.deepOrange),
              title: const Text('Herramientas Admin'),
              subtitle: const Text('Crear horarios masivos y más utilidades'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminToolsPage(),
                  ),
                );
              },
            ),
          ],

          const Divider(),

          // Navegación adicional
          ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.blue),
            title: const Text('Doctores'),
            subtitle: const Text('Lista de especialistas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorsPage(),
                ),
              );
            },
          ),

          const Divider(),

          // Perfil
          ListTile(
            leading: const Icon(Icons.person, color: Colors.grey),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(user: currentUser),
                ),
              );
            },
          ),

          // Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              Navigator.pop(context);
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SimpleLoginPage()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
      },
    );
  }

  /// Obtiene el usuario actual desde Firestore si no se proporciona
  Future<UserModel?> _getUser() async {
    if (user != null) {
      logInfo('🔍 DEBUG AppDrawer - Usando usuario proporcionado: ${user!.name}, role: ${user!.role}, isDoctor: ${user!.isDoctor}');
      return user;
    }
    
    final currentAuthUser = FirebaseAuth.instance.currentUser;
    if (currentAuthUser == null) {
      logInfo('🔍 DEBUG AppDrawer - No hay usuario autenticado');
      return null;
    }
    
    try {
      final userFromFirestore = await FirestoreService.getUser(currentAuthUser.uid);
      if (userFromFirestore != null) {
        logInfo('🔍 DEBUG AppDrawer - Usuario cargado de Firestore: ${userFromFirestore.name}, role: ${userFromFirestore.role}, isDoctor: ${userFromFirestore.isDoctor}');
      } else {
        logInfo('🔍 DEBUG AppDrawer - Usuario no encontrado en Firestore');
      }
      return userFromFirestore;
    } catch (e) {
      logInfo('🔍 DEBUG AppDrawer - Error al obtener usuario: $e');
      return null;
    }
  }
}

