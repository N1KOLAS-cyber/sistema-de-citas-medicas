import 'package:equatable/equatable.dart';

/// Estados del Dashboard BLoC
class DashboardState extends Equatable {
  final bool loading;
  final int totalAppointments;
  final int pendingAppointments;
  final int totalPatients;
  final Map<String, int> monthlyAppointments; // yyyy-MM -> count
  final List<int>? weekDayCounts; // 0..6
  final Map<String, int> byStatus;
  final String? error;

  const DashboardState({
    this.loading = false,
    this.totalAppointments = 0,
    this.pendingAppointments = 0,
    this.totalPatients = 0,
    this.monthlyAppointments = const {},
    this.weekDayCounts,
    this.byStatus = const {},
    this.error,
  });

  DashboardState copyWith({
    bool? loading,
    int? totalAppointments,
    int? pendingAppointments,
    int? totalPatients,
    Map<String, int>? monthlyAppointments,
    List<int>? weekDayCounts,
    Map<String, int>? byStatus,
    String? error,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      pendingAppointments: pendingAppointments ?? this.pendingAppointments,
      totalPatients: totalPatients ?? this.totalPatients,
      monthlyAppointments: monthlyAppointments ?? this.monthlyAppointments,
      weekDayCounts: weekDayCounts ?? this.weekDayCounts,
      byStatus: byStatus ?? this.byStatus,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        totalAppointments,
        pendingAppointments,
        totalPatients,
        monthlyAppointments,
        weekDayCounts,
        byStatus,
        error,
      ];
}
