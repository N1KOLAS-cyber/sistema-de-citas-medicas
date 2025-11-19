import 'package:flutter/material.dart';
import '../services/bulk_availability_service.dart';
import '../services/migration_service.dart';
import '../utils/integration_helper.dart';

/// Página de herramientas de administración
class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  bool _loading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Herramientas de Administración"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    '⚙️ Herramientas del Sistema',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Funciones de administración para gestionar el sistema',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Sección de Horarios
                  _buildSectionTitle('📅 Gestión de Horarios'),
                  const SizedBox(height: 12),
                  
                  _buildAdminCard(
                    title: 'Crear Horarios para Todos los Doctores',
                    subtitle: 'Genera horarios estándar (9am-5pm) para los próximos 7 días',
                    icon: Icons.auto_awesome,
                    color: Colors.green,
                    onTap: () => _createScheduleForAllDoctors(7),
                  ),
                  
                  _buildAdminCard(
                    title: 'Crear Horarios - 30 Días',
                    subtitle: 'Genera horarios para el próximo mes completo',
                    icon: Icons.calendar_month,
                    color: Colors.blue,
                    onTap: () => _createScheduleForAllDoctors(30),
                  ),

                  _buildAdminCard(
                    title: 'Estadísticas de Horarios',
                    subtitle: 'Ver resumen de horarios disponibles/ocupados',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    onTap: _showAvailabilityStats,
                  ),

                  const SizedBox(height: 24),

                  // Sección de Migración
                  _buildSectionTitle('🔄 Migración de Datos'),
                  const SizedBox(height: 12),
                  
                  _buildAdminCard(
                    title: 'Migrar Usuarios',
                    subtitle: 'Copiar de "users" a "usuarios"',
                    icon: Icons.people,
                    color: Colors.orange,
                    onTap: _migrateUsers,
                  ),

                  _buildAdminCard(
                    title: 'Migrar Citas',
                    subtitle: 'Copiar de "appointments" a "citas"',
                    icon: Icons.event,
                    color: Colors.orange,
                    onTap: _migrateAppointments,
                  ),

                  const SizedBox(height: 24),

                  // Sección de Verificación
                  _buildSectionTitle('🔍 Verificación del Sistema'),
                  const SizedBox(height: 12),
                  
                  _buildAdminCard(
                    title: 'Verificar Integración',
                    subtitle: 'Revisar estado de colecciones e índices',
                    icon: Icons.verified,
                    color: Colors.indigo,
                    onTap: _checkIntegration,
                  ),

                  _buildAdminCard(
                    title: 'Ver Estadísticas Generales',
                    subtitle: 'Resumen completo del sistema',
                    icon: Icons.dashboard,
                    color: Colors.teal,
                    onTap: _showGeneralStats,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// Crear horarios para todos los doctores
  Future<void> _createScheduleForAllDoctors(int days) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Horarios Masivamente'),
        content: Text(
          '¿Deseas crear horarios estándar (9am-5pm) para TODOS los doctores '
          'durante los próximos $days días?\n\n'
          'Esto creará automáticamente 8 horarios por día para cada doctor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear Horarios'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _statusMessage = 'Creando horarios para todos los doctores...';
    });

    Map<String, dynamic> result = await BulkAvailabilityService.createScheduleForAllDoctors(
      daysAhead: days,
    );

    setState(() => _loading = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: result['success'] ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              const Text('Resultado'),
            ],
          ),
          content: result['success']
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ Doctores procesados: ${result['doctorsProcessed']}'),
                    Text('✅ Horarios creados: ${result['totalSlots']}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Los horarios están listos para ser usados.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Text('Error: ${result['error']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showAvailabilityStats() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Obteniendo estadísticas...';
    });

    Map<String, dynamic> stats = await BulkAvailabilityService.getAvailabilityStats();

    setState(() => _loading = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 Estadísticas de Horarios'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total de horarios:', '${stats['total'] ?? 0}'),
              _buildStatRow('Disponibles:', '${stats['available'] ?? 0}', Colors.green),
              _buildStatRow('Ocupados:', '${stats['occupied'] ?? 0}', Colors.orange),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _migrateUsers() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Migrando usuarios...';
    });

    int migrated = await MigrationService.migrateUsersToUsuarios();

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $migrated usuarios migrados'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _migrateAppointments() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Migrando citas...';
    });

    int migrated = await MigrationService.migrateAppointmentsToCitas();

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $migrated citas migradas'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _checkIntegration() async {
    await IntegrationHelper.showIntegrationDialog(context);
  }

  Future<void> _showGeneralStats() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Obteniendo estadísticas...';
    });

    Map<String, dynamic> stats = await MigrationService.getCollectionStats();

    setState(() => _loading = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 Estadísticas Generales'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Colecciones Nuevas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildStatRow('Usuarios:', '${stats['usuarios_new'] ?? 0}'),
                _buildStatRow('Citas:', '${stats['citas_new'] ?? 0}'),
                _buildStatRow('Horarios:', '${stats['disponibilidad_medicos'] ?? 0}'),
                const SizedBox(height: 16),
                const Text(
                  'Colecciones Antiguas:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                _buildStatRow('users:', '${stats['users_old'] ?? 0}', Colors.grey),
                _buildStatRow('appointments:', '${stats['appointments_old'] ?? 0}', Colors.grey),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

