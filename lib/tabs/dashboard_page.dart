import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/app_drawer.dart';

class DashboardPage extends StatefulWidget {
  final UserModel user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? touchedIndex;
  
  // Mapeo de estados a índices para la interacción con la leyenda
  Map<String, int> _getStatusIndexMap(int pendientes, int enRevision, int enCurso, int finalizadas) {
    final map = <String, int>{};
    int index = 0;
    if (pendientes > 0) {
      map['pendientes'] = index++;
    }
    if (enRevision > 0) {
      map['enRevision'] = index++;
    }
    if (enCurso > 0) {
      map['enCurso'] = index++;
    }
    if (finalizadas > 0) {
      map['finalizadas'] = index++;
    }
    return map;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream() {
    return _firestore
        .collection('citas')
        .where('doctorId', isEqualTo: widget.user.id)
        .snapshots();
  }

  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate == null) return null;
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is DateTime) return rawDate;
    if (rawDate is int) return DateTime.fromMillisecondsSinceEpoch(rawDate);
    try {
      return (rawDate as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: AppDrawer(user: widget.user),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Dashboard del Médico',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _appointmentsStream(),
        builder: (context, snapshot) {
          // Manejo de errores
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar datos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor, intenta nuevamente',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final citas = snapshot.data?.docs ?? [];
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);

          // Calcular estadísticas del mes actual
          int citasDelMes = 0;
          Set<String> pacientesUnicos = {};
          
          for (var doc in citas) {
            final data = doc.data();
            final fecha = _parseDate(data['appointmentDate'] ?? data['fechaHora']);
            final patientId = data['patientId'] ?? data['patientName'];
            
            if (fecha != null && fecha.isAfter(startOfMonth.subtract(const Duration(days: 1)))) {
              citasDelMes++;
            }
            
            if (patientId != null) {
              pacientesUnicos.add(patientId.toString());
            }
          }

          // Contar citas por estado
          int countByStatus(Set<String> statuses) {
            return citas.where((doc) {
              final status = (doc.data()['status'] ?? '').toString().toLowerCase();
              return statuses.contains(status);
            }).length;
          }

          final pendientesCount = countByStatus({'pending', 'confirmada', 'confirmed', 'pendiente'});
          final enRevisionCount = countByStatus({'en revisión', 'review'});
          final enCursoCount = countByStatus({'en curso', 'in progress'});
          final finalizadasCount = countByStatus({'completed', 'completada', 'finalizada'});
          final totalCitas = citas.length;
          final totalPacientes = pacientesUnicos.length;

          final porcentajeFinalizadas = totalCitas > 0 
              ? (finalizadasCount / totalCitas * 100) 
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjetas superiores con estadísticas principales
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Citas del Mes',
                              citasDelMes.toString(),
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Total de Pacientes',
                              totalPacientes.toString(),
                              Icons.people,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Total de Citas',
                              totalCitas.toString(),
                              Icons.event_note,
                              Colors.orange,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildStatCard(
                            'Citas del Mes',
                            citasDelMes.toString(),
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Total de Pacientes',
                            totalPacientes.toString(),
                            Icons.people,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Total de Citas',
                            totalCitas.toString(),
                            Icons.event_note,
                            Colors.orange,
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Layout principal: Resumen de estado y Actividad reciente
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resumen de estado con gráfico de dona
                          Expanded(
                            flex: 2,
                            child: _buildStatusSummaryCard(
                              totalCitas,
                              pendientesCount,
                              enRevisionCount,
                              enCursoCount,
                              finalizadasCount,
                              porcentajeFinalizadas,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Actividad reciente
                          Expanded(
                            flex: 1,
                            child: _buildRecentActivityCard(citas),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildStatusSummaryCard(
                            totalCitas,
                            pendientesCount,
                            enRevisionCount,
                            enCursoCount,
                            finalizadasCount,
                            porcentajeFinalizadas,
                          ),
                          const SizedBox(height: 20),
                          _buildRecentActivityCard(citas),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Nuevas gráficas: Citas por mes y Completadas vs Canceladas
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gráfica de citas por mes
                          Expanded(
                            child: _buildMonthlyAppointmentsCard(citas),
                          ),
                          const SizedBox(width: 20),
                          // Gráfica de citas completadas vs canceladas
                          Expanded(
                            child: _buildCompletionStatusCard(citas),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildMonthlyAppointmentsCard(citas),
                          const SizedBox(height: 20),
                          _buildCompletionStatusCard(citas),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget para tarjetas de estadísticas principales
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Función helper para construir las secciones del gráfico
  List<PieChartSectionData> _buildPieChartSections(
    int totalCitas,
    int pendientes,
    int enRevision,
    int enCurso,
    int finalizadas,
  ) {
    final List<PieChartSectionData> sections = [];

    int currentIndex = 0;
    
    if (pendientes > 0) {
      final isHighlighted = touchedIndex == currentIndex;
      sections.add(
        PieChartSectionData(
          value: pendientes.toDouble(),
          color: Colors.blue,
          title: '',
          radius: isHighlighted ? 50 : 45,
        ),
      );
      currentIndex++;
    }

    if (enRevision > 0) {
      final isHighlighted = touchedIndex == currentIndex;
      sections.add(
        PieChartSectionData(
          value: enRevision.toDouble(),
          color: Colors.purple,
          title: '',
          radius: isHighlighted ? 50 : 45,
        ),
      );
      currentIndex++;
    }

    if (enCurso > 0) {
      final isHighlighted = touchedIndex == currentIndex;
      sections.add(
        PieChartSectionData(
          value: enCurso.toDouble(),
          color: Colors.green,
          title: '',
          radius: isHighlighted ? 50 : 45,
        ),
      );
      currentIndex++;
    }

    if (finalizadas > 0) {
      final isHighlighted = touchedIndex == currentIndex;
      sections.add(
        PieChartSectionData(
          value: finalizadas.toDouble(),
          color: Colors.orange,
          title: '',
          radius: isHighlighted ? 50 : 45,
        ),
      );
      currentIndex++;
    }

    if (totalCitas == 0) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: Colors.grey[300]!,
          title: 'Sin datos',
          radius: 45,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    return sections;
  }

  // Widget para el resumen de estado con gráfico de dona
  Widget _buildStatusSummaryCard(
    int totalCitas,
    int pendientes,
    int enRevision,
    int enCurso,
    int finalizadas,
    double porcentajeFinalizadas,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
          const Text(
            'Resumen de estado',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Obtén una instantánea del estado de tus citas y pacientes.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              
              return isCompact
                  ? Column(
                            children: [
                        // Gráfica de dona
                              SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50,
                                  startDegreeOffset: -90,
                                  sections: _buildPieChartSections(
                                    totalCitas,
                                    pendientes,
                                    enRevision,
                                    enCurso,
                                    finalizadas,
                                  ),
                                  pieTouchData: PieTouchData(
                                    enabled: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Leyenda
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInteractiveLegendItem(
                              Colors.blue,
                              'Pendientes',
                              'pendientes',
                              pendientes,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                            ),
                            const SizedBox(height: 8),
                            _buildInteractiveLegendItem(
                              Colors.purple,
                              'En revisión',
                              'enRevision',
                              enRevision,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                            ),
                            const SizedBox(height: 8),
                            _buildInteractiveLegendItem(
                              Colors.green,
                              'En curso',
                              'enCurso',
                              enCurso,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                            ),
                            const SizedBox(height: 8),
                            _buildInteractiveLegendItem(
                              Colors.orange,
                              'Finalizadas',
                              'finalizadas',
                              finalizadas,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                        ),
                      ],
                    ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gráfica de dona a la izquierda (más pequeña)
                        RepaintBoundary(
                          child: SizedBox(
                            width: 140,
                            height: 140,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 45,
                                startDegreeOffset: -90,
                                sections: _buildPieChartSections(
                                  totalCitas,
                                  pendientes,
                                  enRevision,
                                  enCurso,
                                  finalizadas,
                                ),
                                pieTouchData: PieTouchData(
                                  enabled: false,
                                ),
                                centerSpaceColor: Colors.white,
                              ),
                              swapAnimationDuration: const Duration(milliseconds: 300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Leyenda a la derecha
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInteractiveLegendItem(
                              Colors.blue,
                              'Pendientes',
                              'pendientes',
                              pendientes,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                            ),
                            const SizedBox(height: 8),
                            _buildInteractiveLegendItem(
                              Colors.purple,
                              'En revisión',
                              'enRevision',
                              enRevision,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                            ),
                            const SizedBox(height: 8),
                            _buildInteractiveLegendItem(
                              Colors.green,
                              'En curso',
                              'enCurso',
                              enCurso,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                            ),
                            const SizedBox(height: 8),
                            _buildInteractiveLegendItem(
                              Colors.orange,
                              'Finalizadas',
                              'finalizadas',
                              finalizadas,
                              _getStatusIndexMap(pendientes, enRevision, enCurso, finalizadas),
                              totalCitas,
                            ),
                          ],
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // Widget para item de leyenda interactivo
  Widget _buildInteractiveLegendItem(
    Color color,
    String label,
    String statusKey,
    int count,
    Map<String, int> statusIndexMap,
    int totalCitas,
  ) {
    if (count == 0) {
      return const SizedBox.shrink(); // No mostrar si no hay citas
    }
    
    final index = statusIndexMap[statusKey];
    final isHighlighted = touchedIndex == index;
    final percentage = totalCitas > 0 
        ? (count / totalCitas * 100).toStringAsFixed(0)
        : '0';
    
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) {
          if (touchedIndex != index) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  touchedIndex = index;
                });
              }
            });
          }
        },
        onExit: (_) {
          if (touchedIndex == index) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  touchedIndex = null;
                });
              }
            });
          }
        },
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    if (isHighlighted)
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$label: $count ($percentage%)',
                style: TextStyle(
                  color: isHighlighted ? color : Colors.black87,
                  fontSize: 14,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Widget para actividad reciente
  Widget _buildRecentActivityCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
  ) {
    // Obtener las últimas 5 citas ordenadas por fecha
    final sortedCitas = citas.map((doc) {
      final data = doc.data();
      final fecha = _parseDate(data['appointmentDate'] ?? data['fechaHora']) ?? DateTime.now();
      return {'doc': doc, 'fecha': fecha};
    }).toList()
      ..sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    final recentCitas = sortedCitas.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          const Text(
            'Actividad reciente',
                  style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
                  ),
                ),
          const SizedBox(height: 8),
                    Text(
            'Mantente al día de lo que está pasando',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          if (recentCitas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No hay actividad reciente',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...recentCitas.map((item) {
              final doc = item['doc'] as QueryDocumentSnapshot<Map<String, dynamic>>;
              final data = doc.data();
              final fecha = item['fecha'] as DateTime;
              final nombre = data['patientName'] ?? 'Paciente';
              final status = data['status'] ?? '';
              final iniciales = nombre.toString().split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join().toUpperCase();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                      child: Text(
                        iniciales.isNotEmpty ? iniciales : 'P',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                            '$nombre ${_getActionText(status)}',
                style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                            _formatTimeAgo(fecha),
                style: TextStyle(
                              color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
                      ),
          ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'completada':
      case 'finalizada':
        return Colors.orange;
      case 'en revisión':
      case 'review':
        return Colors.purple;
      case 'en curso':
      case 'in progress':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getActionText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'completada':
      case 'finalizada':
        return 'completó una cita';
      case 'en revisión':
      case 'review':
        return 'tiene una cita en revisión';
      case 'en curso':
      case 'in progress':
        return 'tiene una cita en curso';
      default:
        return 'tiene una cita pendiente';
    }
  }

  String _formatTimeAgo(DateTime fecha) {
    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inDays > 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace unos momentos';
    }
  }

  // Gráfica de citas por mes (Barra)
  Widget _buildMonthlyAppointmentsCard(List<QueryDocumentSnapshot> citas) {
    try {
      // Contar citas por mes (últimos 6 meses)
      final now = DateTime.now();
      final monthKeys = <String>[];
      final monthNames = <String>[];
      final monthCounts = <String, int>{};

      // Inicializar los últimos 6 meses
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final monthName = _getMonthName(date.month);
        monthKeys.add(monthKey);
        monthNames.add(monthName);
        monthCounts[monthKey] = 0;
      }

      // Contar citas por mes
      for (var cita in citas) {
        try {
          final data = cita.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final fechaData = data['appointmentDate'] ?? data['fechaHora'] ?? data['fecha'];
          if (fechaData != null) {
            final fecha = _parseDate(fechaData);
            if (fecha != null) {
              final monthKey = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
              if (monthCounts.containsKey(monthKey)) {
                monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          // Continuar con la siguiente cita si hay error
          continue;
        }
      }

      final maxCount = monthCounts.values.isNotEmpty 
          ? monthCounts.values.reduce((a, b) => a > b ? a : b).toDouble()
          : 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Citas por Mes',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
                  SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount > 0 ? maxCount + 2 : 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${monthNames[group.x.toInt()]}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${rod.toY.toInt()} citas',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthNames.length) {
                          final monthName = monthNames[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                              monthName.substring(0, 3), // Solo las primeras 3 letras
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return Container();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
            ),
          );
        },
      ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(monthNames.length, (index) {
                  final monthKey = monthKeys[index];
                  final count = monthCounts[monthKey] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: Colors.blue,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
        ),
      );
    } catch (e) {
      // Si hay error, mostrar mensaje
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Error al cargar gráfica',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
  }

  // Gráfica de completadas vs canceladas (Pastel)
  Widget _buildCompletionStatusCard(List<QueryDocumentSnapshot> citas) {
    try {
      int completadas = 0;
    int canceladas = 0;
    int enProceso = 0;

    for (var cita in citas) {
      final data = cita.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      
      if (status.contains('finalizada') || status.contains('completed')) {
        completadas++;
      } else if (status.contains('cancelada') || status.contains('cancelled')) {
        canceladas++;
      } else {
        enProceso++;
      }
    }

    final total = completadas + canceladas + enProceso;
    final porcentajeCompletadas = total > 0 ? (completadas / total * 100).toDouble() : 0.0;
    final porcentajeCanceladas = total > 0 ? (canceladas / total * 100).toDouble() : 0.0;
    final porcentajeEnProceso = total > 0 ? (enProceso / total * 100).toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
          const Text(
                'Estado de Citas',
            style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No hay datos disponibles',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                // Gráfica de pastel
          SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        if (completadas > 0)
                          PieChartSectionData(
                            value: completadas.toDouble(),
                            color: Colors.green,
                            title: '${porcentajeCompletadas.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (canceladas > 0)
                          PieChartSectionData(
                            value: canceladas.toDouble(),
                            color: Colors.red,
                            title: '${porcentajeCanceladas.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (enProceso > 0)
                          PieChartSectionData(
                            value: enProceso.toDouble(),
                            color: Colors.amber,
                            title: '${porcentajeEnProceso.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
                ),
                const SizedBox(width: 32),
                // Leyenda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (completadas > 0)
                        _buildLegendRow(
                          Colors.green,
                          'Completadas',
                          completadas,
                          porcentajeCompletadas,
                        ),
                      if (completadas > 0 && (canceladas > 0 || enProceso > 0))
                        const SizedBox(height: 12),
                      if (canceladas > 0)
                        _buildLegendRow(
                          Colors.red,
                          'Canceladas',
                          canceladas,
                          porcentajeCanceladas,
                        ),
                      if (canceladas > 0 && enProceso > 0)
                        const SizedBox(height: 12),
                      if (enProceso > 0)
                        _buildLegendRow(
                          Colors.amber,
                          'En Proceso',
                          enProceso,
                          porcentajeEnProceso,
                        ),
                    ],
                  ),
                ),
              ],
          ),
        ],
      ),
    );
    } catch (e) {
      // Si hay error, mostrar mensaje
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Error al cargar gráfica',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
  }

  Widget _buildLegendRow(Color color, String label, int count, double percentage) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count citas (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return monthNames[month - 1];
  }
}
