import 'package:equatable/equatable.dart';

/// Eventos del Dashboard BLoC
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializar streams para el doctorId dado
class DashboardStarted extends DashboardEvent {
  final String doctorId;

  const DashboardStarted(this.doctorId);

  @override
  List<Object?> get props => [doctorId];
}

/// Refrescar datos manualmente
class DashboardRefreshRequested extends DashboardEvent {}
