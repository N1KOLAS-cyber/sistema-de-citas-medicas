//
// PROFILE PAGE - PÁGINA DE PERFIL DEL USUARIO
//
// Este archivo contiene la página de perfil del usuario actual.
// Muestra información personal, estadísticas y opciones de configuración.
//
// FUNCIONALIDADES:
// - Visualización de información personal del usuario
// - Estadísticas profesionales (para doctores)
// - Edición de perfil
// - Cambio de contraseña
// - Acceso a privacidad y términos
// - Ayuda y soporte
// - Cerrar sesión
//
// ESTRUCTURA:
// - Header con avatar y información básica
// - Sección de información personal
// - Estadísticas (solo para doctores)
// - Acciones y configuraciones
//
// VISUALIZACIÓN: Página con diseño moderno, gradientes, tarjetas
// informativas y navegación intuitiva a diferentes opciones.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'privacy_terms_page.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(user: _currentUser),
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header con información principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: _currentUser.profileImage != null
                        ? ClipOval(
                            child: Image.network(
                              _currentUser.profileImage!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre
                  Text(
                    _currentUser.isDoctor ? "Dr. ${_currentUser.name}" : _currentUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Especialidad (si es doctor)
                  if (_currentUser.isDoctor && _currentUser.specialty != null)
                    Text(
                      _currentUser.specialty!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  
                  // Email
                  Text(
                    _currentUser.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Información detallada
            _buildInfoSection(),
            const SizedBox(height: 24),

            // Estadísticas (solo para doctores)
            if (_currentUser.isDoctor) ...[
              _buildStatsSection(),
              const SizedBox(height: 24),
            ],

            // Acciones
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  ///
  /// Construye la sección de información personal del usuario
  /// @return Widget - Sección con información personal
  Widget _buildInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información Personal",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, "Nombre", _currentUser.name),
            _buildInfoRow(Icons.email, "Email", _currentUser.email),
            _buildInfoRow(Icons.phone, "Teléfono", _currentUser.phone),
            _buildRoleSelector(),
            if (_currentUser.isDoctor) ...[
              _buildInfoRow(Icons.medical_services, "Especialidad", _currentUser.specialty ?? 'No especificada'),
              _buildInfoRow(Icons.badge, "Licencia", _currentUser.licenseNumber ?? 'No disponible'),
            ],
            if (!_currentUser.isDoctor && _currentUser.medicalHistory != null && _currentUser.medicalHistory!.isNotEmpty)
              _buildInfoRow(Icons.local_hospital, "Historial Médico", _currentUser.medicalHistory!),
            _buildInfoRow(Icons.calendar_today, "Miembro desde", _formatDate(_currentUser.createdAt)),
          ],
        ),
      ),
    );
  }

  ///
  /// Construye la sección de estadísticas profesionales (solo para doctores)
  /// @return Widget - Sección con estadísticas del doctor
  Widget _buildStatsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Estadísticas Profesionales",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    "Citas Totales",
                    "${_currentUser.totalAppointments ?? 0}",
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    "Calificación",
                    "${_currentUser.rating?.toStringAsFixed(1) ?? '0.0'} ⭐",
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ///
  /// Construye un elemento de estadística individual
  /// @param title - Título de la estadística
  /// @param value - Valor de la estadística
  /// @param icon - Icono representativo
  /// @param color - Color del tema
  /// @return Widget - Elemento de estadística
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  ///
  /// Construye la sección de acciones y configuraciones
  /// @return Widget - Sección con acciones disponibles
  Widget _buildActionsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Acciones",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              Icons.edit,
              "Editar Perfil",
              "Actualiza tu información personal",
              _editProfile,
            ),
            _buildActionTile(
              Icons.security,
              "Cambiar Contraseña",
              "Actualiza tu contraseña de acceso",
              _changePassword,
            ),
            _buildActionTile(
              Icons.privacy_tip,
              "Privacidad y Términos",
              "Lee nuestra política de privacidad",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyTermsPage(),
                  ),
                );
              },
            ),
            _buildActionTile(
              Icons.help,
              "Ayuda y Soporte",
              "Obtén ayuda con la aplicación",
              _showHelp,
            ),
            _buildActionTile(
              Icons.logout,
              "Cerrar Sesión",
              "Salir de tu cuenta",
              _logout,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  ///
  /// Construye el campo de rol (solo lectura)
  /// @return Widget - Campo de rol de solo lectura
  Widget _buildRoleSelector() {
    final String roleDisplay = _currentUser.role ?? (_currentUser.isDoctor ? 'Médico' : 'Paciente');
    return _buildInfoRow(Icons.person_outline, "Rol", roleDisplay);
  }

  ///
  /// Construye una fila de información personal
  /// @param icon - Icono del campo
  /// @param label - Etiqueta del campo
  /// @param value - Valor del campo
  /// @return Widget - Fila de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  ///
  /// Construye una tarjeta de acción
  /// @param icon - Icono de la acción
  /// @param title - Título de la acción
  /// @param subtitle - Descripción de la acción
  /// @param onTap - Función a ejecutar al tocar
  /// @param isDestructive - Si es una acción destructiva (roja)
  /// @return Widget - Tarjeta de acción
  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive 
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.indigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.indigo,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  ///
  /// Formatea una fecha para mostrar en la interfaz
  /// @param date - Fecha a formatear
  /// @return String - Fecha formateada
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  ///
  /// Navega a la página de edición de perfil
  /// Actualiza los datos del usuario si se guardaron cambios
  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: _currentUser),
      ),
    );

    if (!mounted) return;

    // Si se guardaron cambios, recargar los datos del usuario
    if (result == true) {
      try {
        final updatedUser = await FirestoreService.getUser(_currentUser.id);
        if (!mounted) return;
        if (updatedUser != null) {
          setState(() {
            _currentUser = updatedUser;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Perfil actualizado exitosamente"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al recargar perfil: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ///
  /// Muestra mensaje de funcionalidad en desarrollo para cambio de contraseña
  void _changePassword() {
    //  Implementar cambio de contraseña
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Función de cambiar contraseña en desarrollo"),
      ),
    );
  }

  ///
  /// Muestra diálogo con información de ayuda y soporte
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ayuda y Soporte"),
        content: const Text(
          "Si necesitas ayuda con la aplicación, puedes contactarnos a través de:\n\n"
          "📧 Email: soporte@sistemacitas.com\n"
          "📞 Teléfono: +1 (555) 123-4567\n"
          "💬 Chat en vivo: Disponible 24/7",
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
  /// Muestra diálogo de confirmación para cerrar sesión
  /// Cierra la sesión del usuario y regresa al login
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              // Cerrar el diálogo primero
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              try {
                // Cerrar sesión en Firebase Auth
                await _auth.signOut();
                // Limpiar datos de sesión guardados
                await AuthService.clearSession();
                
                // Pequeño delay para asegurar que Firebase Auth actualice el estado
                await Future.delayed(const Duration(milliseconds: 100));
                
                if (!context.mounted) return;
                
                // Navegar al login eliminando todas las rutas anteriores
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              } catch (e) {
                // Si hay error, aún así navegar al login
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text("Cerrar Sesión"),
          ),
        ],
      ),
    );
  }
}
