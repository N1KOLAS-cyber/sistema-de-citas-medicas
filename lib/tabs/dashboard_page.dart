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
      backgroundColor: const Color(0xFFF4F6FB),
      drawer: AppDrawer(user: widget.user),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4EB7),
        title: const Text('Dashboard del Médico'),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final citas = snapshot.data?.docs ?? [];
          final totalCitas = citas.length;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          DateTime startMonths(int months) =>
              DateTime(now.year, now.month - months, now.day);

          String extractPatientId(Map<String, dynamic> data, String docId) {
            return (data['patientId'] ??
                    data['nombreUsuario'] ??
                    data['patientEmail'] ??
                    docId)
                .toString();
          }

          int countAppointmentsWithin(int months, {Set<String>? statuses}) {
            final cutoff = startMonths(months);
            return citas.where((doc) {
              final fecha =
                  _parseDate(doc.data()['appointmentDate'] ?? doc.data()['fechaHora']);
              if (fecha == null || fecha.isBefore(cutoff)) return false;
              if (statuses != null && statuses.isNotEmpty) {
                final status = (doc.data()['status'] ?? '').toString().toLowerCase();
                if (!statuses.contains(status)) return false;
              }
              return true;
            }).length;
          }

          int countUniquePatientsWithin(int months) {
            final patients = <String>{};
            final cutoff = startMonths(months);
            for (final doc in citas) {
              final fecha =
                  _parseDate(doc.data()['appointmentDate'] ?? doc.data()['fechaHora']);
              if (fecha == null || fecha.isBefore(cutoff)) continue;
              patients.add(extractPatientId(doc.data(), doc.id));
            }
            return patients.length;
          }

          final Map<String, DateTime> firstAppointmentByPatient = {};
          for (final doc in citas) {
            final fecha =
                _parseDate(doc.data()['appointmentDate'] ?? doc.data()['fechaHora']);
            if (fecha == null) continue;
            final id = extractPatientId(doc.data(), doc.id);
            final current = firstAppointmentByPatient[id];
            if (current == null || fecha.isBefore(current)) {
              firstAppointmentByPatient[id] = fecha;
            }
          }

          int countByStatus(Set<String> statuses) {
            return citas.where((doc) {
              final status = (doc.data()['status'] ?? '').toString().toLowerCase();
              return statuses.contains(status);
            }).length;
          }

          final citasHoy = citas.where((doc) {
            final fecha =
                _parseDate(doc.data()['appointmentDate'] ?? doc.data()['fechaHora']);
            if (fecha == null) return false;
            final truncated = DateTime(fecha.year, fecha.month, fecha.day);
            return truncated == today;
          }).length;

          final totalPacientes24m = countUniquePatientsWithin(24);
          final totalCitas3m = countAppointmentsWithin(3);
          final totalCitas6m = countAppointmentsWithin(6);
          final completadas3m =
              countAppointmentsWithin(3, statuses: {'completed'});
          final completadas6m =
              countAppointmentsWithin(6, statuses: {'completed'});
          final pendientesCount =
              countByStatus({'pending', 'confirmada', 'confirmed'});
          final canceladasCount =
              countByStatus({'cancelled', 'cancelada', 'canceled'});

          const int objetivoCitas = 32;
          const int objetivoPacientes = 32;

          double safeRatio(int value, int base) => base <= 0 ? 0 : value / base;

          final ratioActividad3 = safeRatio(completadas3m, totalCitas3m);
          final ratioActividad6 = safeRatio(completadas6m, totalCitas6m);

          final last90Days = startMonths(3);
          final dailyCounts = <DateTime, int>{};
          for (final doc in citas) {
            final fecha =
                _parseDate(doc.data()['appointmentDate'] ?? doc.data()['fechaHora']);
            if (fecha == null || fecha.isBefore(last90Days)) continue;
            final dayKey = DateTime(fecha.year, fecha.month, fecha.day);
            dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;
          }

          final lineDates = List.generate(
            30,
            (i) => today.subtract(Duration(days: 29 - i)),
          );
          final lineValues = lineDates.map((d) => dailyCounts[d] ?? 0).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isCompact = maxWidth < 640;
              final spacing = 16.0;
              final columns = maxWidth >= 1400
                  ? 4
                  : maxWidth >= 1100
                      ? 3
                      : maxWidth >= 720
                          ? 2
                          : 1;
              final cardWidth =
                  columns == 1 ? maxWidth : (maxWidth - spacing * (columns - 1)) / columns;

              double clampWidth(double value, double min, double max) {
                if (value < min) return min;
                if (value > max) return max;
                return value;
              }

              final donutWidth = columns == 1
                  ? clampWidth(maxWidth * 0.6, 160, 200)
                  : clampWidth(cardWidth, 150, 180);
              final donutConfigs = [
                _DonutConfig(
                  title: 'Actividad últimos 3 meses',
                  percentage: ratioActividad3 * 100,
                  value: completadas3m,
                  base: totalCitas3m,
                  detail:
                      '$completadas3m completadas / $totalCitas3m registradas (meta $objetivoCitas)',
                ),
                _DonutConfig(
                  title: 'Actividad últimos 6 meses',
                  percentage: ratioActividad6 * 100,
                  value: completadas6m,
                  base: totalCitas6m,
                  detail:
                      '$completadas6m completadas / $totalCitas6m registradas (meta $objetivoCitas)',
                ),
                _DonutConfig(
                  title: 'Citas pendientes',
                  percentage: safeRatio(pendientesCount, totalCitas) * 100,
                  value: pendientesCount,
                  base: totalCitas,
                  detail: '$pendientesCount pendientes / $totalCitas totales',
                ),
                _DonutConfig(
                  title: 'Citas canceladas',
                  percentage: safeRatio(canceladasCount, totalCitas) * 100,
                  value: canceladasCount,
                  base: totalCitas,
                  detail: '$canceladasCount canceladas / $totalCitas totales',
                ),
              ];

              final horizontalPadding = isCompact ? 12.0 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(
                                width: isCompact ? 220 : 260,
                                child: _buildMetricColumn(
                                  title: 'Citas totales',
                                  value: totalCitas,
                                  comparison: 'Hoy: $citasHoy',
                                  percentage: 100,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: isCompact ? 220 : 260,
                                child: _buildMetricColumn(
                                  title: 'Pacientes únicos',
                                  value: totalPacientes24m,
                                  comparison: 'Pendientes: $pendientesCount',
                                  percentage: safeRatio(totalPacientes24m, objetivoPacientes) * 100,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: isCompact ? 220 : 260,
                                child: _buildMetricColumn(
                                  title: 'Citas últimos 3 meses',
                                  value: totalCitas3m,
                                  comparison: 'Completadas: $completadas3m',
                                  percentage: ratioActividad3 * 100,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: isCompact ? 220 : 260,
                                child: _buildMetricColumn(
                                  title: 'Citas últimos 6 meses',
                                  value: totalCitas6m,
                                  comparison: 'Completadas: $completadas6m',
                                  percentage: ratioActividad6 * 100,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: List.generate(donutConfigs.length, (index) {
                            final config = donutConfigs[index];
                            return _buildDonutCard(
                              title: config.title,
                              percentage: config.percentage,
                              value: config.value,
                              baseValue: config.base,
                              width: donutWidth,
                              detailText: config.detail,
                            );
                          }),
                        ),
                        const SizedBox(height: 32),
                        _buildLineCard(lineValues),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E4EB7),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar datos'),
                            onPressed: () => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricColumn({
    required String title,
    required int value,
    required String comparison,
    required double percentage,
  }) {
    final percentText = '${percentage.toStringAsFixed(2)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0C0F1A))),
                const SizedBox(height: 6),
                Text(
                  'Diferencia porcentual',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      percentText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF16A34A)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comparison,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutCard({
    required String title,
    required double percentage,
    required int value,
    required int baseValue,
    required double width,
    required String detailText,
  }) {
    double clampDouble(double value, double min, double max) {
      if (value < min) return min;
      if (value > max) return max;
      return value;
    }

    final normalized =
        baseValue <= 0 ? 0.0 : (percentage.isNaN ? 0.0 : percentage.clamp(0, 100));
    final ratio = normalized / 100;

    final availableWidth = width - 36; // padding horizontal aprox.
    final chartSize = clampDouble(availableWidth * 0.55, 80, 120);
    final ringRadius = clampDouble(chartSize / 2 - 4, 24, chartSize / 2);
    final centerRadius = clampDouble(ringRadius - 14, 14, ringRadius - 4);

    return SizedBox(
      width: width,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animatedRatio, _) {
          final displayPercent = (animatedRatio * 100).clamp(0, 100);
          final remaining = (1 - animatedRatio).clamp(0.001, 1.0);

          return Tooltip(
            message: detailText,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(220),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 13),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E4EC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0C0F1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: chartSize,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: centerRadius,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: animatedRatio <= 0 ? 0.001 : animatedRatio,
                            color: const Color(0xFF6AC3FF),
                            showTitle: false,
                            radius: ringRadius,
                          ),
                          PieChartSectionData(
                            value: remaining,
                            color: const Color(0xFFE6E8EC),
                            showTitle: false,
                            radius: ringRadius,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${displayPercent.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineCard(List<int> values) {
    if (values.every((element) => element == 0)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E4EC)),
        ),
        child: const Text(
          'Sin actividad en los últimos 30 días',
          style: TextStyle(color: Color(0xFF0C0F1A)),
        ),
      );
    }

    final chartSpots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i].toDouble()),
    );

    double maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxY < 1) maxY = 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendencia de citas (30 días)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                titlesData: const FlTitlesData(
                  show: false,
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withAlpha((0.2 * 255).round()),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartSpots,
                    isCurved: true,
                    barWidth: 3,
                    color: const Color(0xFF4B7BEC),
                    dotData: const FlDotData(show: false),
                    aboveBarData: BarAreaData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4B7BEC).withAlpha((0.15 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutConfig {
  final String title;
  final double percentage;
  final int value;
  final int base;
  final String detail;

  const _DonutConfig({
    required this.title,
    required this.percentage,
    required this.value,
    required this.base,
    required this.detail,
  });
}

