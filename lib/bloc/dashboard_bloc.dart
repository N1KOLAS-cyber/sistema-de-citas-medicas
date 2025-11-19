import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../services/firestore_service.dart';

/// BLoC para gestionar el estado del Dashboard con Streams en tiempo real
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  StreamSubscription<int>? _totalSub;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<int>? _patientsSub;
  StreamSubscription<Map<String, int>>? _monthlySub;
  StreamSubscription<List<int>>? _weekDaySub;
  StreamSubscription<Map<String, int>>? _statusSub;

  DashboardBloc() : super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onStarted(DashboardStarted event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    
    try {
      // Cancelar suscripciones previas si existen
      await _cancelSubscriptions();

      // Suscribirse a total de citas
      _totalSub = FirestoreService.totalAppointmentsStream(event.doctorId).listen(
        (count) {
          emit(state.copyWith(totalAppointments: count, loading: false, error: null));
        },
        onError: (e) {
          // No sobrescribir todo el estado, solo agregar el error
          emit(state.copyWith(
            error: 'Error al cargar total de citas: ${e.toString()}',
            loading: false,
          ));
        },
        cancelOnError: false, // Continuar escuchando aunque haya error
      );

      // Suscribirse a citas pendientes
      _pendingSub = FirestoreService.pendingAppointmentsStream(event.doctorId).listen(
        (count) {
          emit(state.copyWith(pendingAppointments: count, error: null));
        },
        onError: (e) {
          emit(state.copyWith(error: 'Error al cargar citas pendientes: ${e.toString()}'));
        },
        cancelOnError: false,
      );

      // Suscribirse a pacientes únicos
      _patientsSub = FirestoreService.totalUniquePatientsStream(event.doctorId).listen(
        (count) {
          emit(state.copyWith(totalPatients: count, error: null));
        },
        onError: (e) {
          emit(state.copyWith(error: 'Error al cargar pacientes: ${e.toString()}'));
        },
        cancelOnError: false,
      );

      // Suscribirse a citas por mes
      _monthlySub = FirestoreService.appointmentsByMonthStream(event.doctorId).listen(
        (map) {
          emit(state.copyWith(monthlyAppointments: map, error: null));
        },
        onError: (e) {
          emit(state.copyWith(error: 'Error al cargar citas por mes: ${e.toString()}'));
        },
        cancelOnError: false,
      );

      // Suscribirse a citas por día de la semana
      _weekDaySub = FirestoreService.appointmentsByWeekDayStream(event.doctorId).listen(
        (list) {
          emit(state.copyWith(weekDayCounts: list, error: null));
        },
        onError: (e) {
          emit(state.copyWith(error: 'Error al cargar citas por día: ${e.toString()}'));
        },
        cancelOnError: false,
      );

      // Suscribirse a citas por estado
      _statusSub = FirestoreService.appointmentsByStatusStream(event.doctorId).listen(
        (byStatus) {
          emit(state.copyWith(byStatus: byStatus, error: null));
        },
        onError: (e) {
          emit(state.copyWith(error: 'Error al cargar citas por estado: ${e.toString()}'));
        },
        cancelOnError: false,
      );

    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onRefresh(DashboardRefreshRequested event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    // Los streams se actualizan automáticamente
    emit(state.copyWith(loading: false));
  }

  Future<void> _cancelSubscriptions() async {
    await _totalSub?.cancel();
    await _pendingSub?.cancel();
    await _patientsSub?.cancel();
    await _monthlySub?.cancel();
    await _weekDaySub?.cancel();
    await _statusSub?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
