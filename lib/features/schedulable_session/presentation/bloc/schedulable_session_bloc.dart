import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/schedulable_session/domain/repositories/schedulable_session_repository.dart';
import 'package:myapp/features/schedulable_session/domain/usecases/get_schedulable_sessions.dart';
import 'package:myapp/features/schedulable_session/domain/usecases/create_schedulable_session.dart';
import 'package:myapp/features/schedulable_session/domain/usecases/update_schedulable_session.dart';
import 'package:myapp/features/schedulable_session/domain/usecases/delete_schedulable_session.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_event.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_state.dart';

class SchedulableSessionBloc extends Bloc<SchedulableSessionEvent, SchedulableSessionState> {
  final GetSchedulableSessions _getSchedulableSessions;
  final CreateSchedulableSession _createSchedulableSession;
  final UpdateSchedulableSession _updateSchedulableSession;
  final DeleteSchedulableSession _deleteSchedulableSession;
  final SchedulableSessionRepository _repository;

  SchedulableSessionBloc({
    required GetSchedulableSessions getSchedulableSessions,
    required CreateSchedulableSession createSchedulableSession,
    required UpdateSchedulableSession updateSchedulableSession,
    required DeleteSchedulableSession deleteSchedulableSession,
    required SchedulableSessionRepository repository,
  })  : _getSchedulableSessions = getSchedulableSessions,
        _createSchedulableSession = createSchedulableSession,
        _updateSchedulableSession = updateSchedulableSession,
        _deleteSchedulableSession = deleteSchedulableSession,
        _repository = repository,
        super(SchedulableSessionInitial()) {
    on<LoadSchedulableSessions>(_onLoadSchedulableSessions);
    on<CreateSchedulableSessionEvent>(_onCreateSchedulableSession);
    on<UpdateSchedulableSessionEvent>(_onUpdateSchedulableSession);
    on<DeleteSchedulableSessionEvent>(_onDeleteSchedulableSession);
  }

  Future<void> _onLoadSchedulableSessions(
    LoadSchedulableSessions event,
    Emitter<SchedulableSessionState> emit,
  ) async {
    emit(SchedulableSessionLoading());

    final result = await _getSchedulableSessions(GetSchedulableSessionsParams(
      instructorId: event.instructorId,
    ));

    result.fold(
      (failure) => emit(SchedulableSessionError(message: failure.message)),
      (sessions) => emit(SchedulableSessionLoaded(sessions: sessions)),
    );
  }

  Future<void> _onCreateSchedulableSession(
    CreateSchedulableSessionEvent event,
    Emitter<SchedulableSessionState> emit,
  ) async {
    emit(SchedulableSessionLoading());

    final result = await _createSchedulableSession(CreateSchedulableSessionParams(
      schedulableSession: event.schedulableSession,
    ));

    result.fold(
      (failure) => emit(SchedulableSessionError(message: failure.message)),
      (_) {
        // Reload sessions after creation
        add(LoadSchedulableSessions(instructorId: event.schedulableSession.instructorId));
      },
    );
  }

  Future<void> _onUpdateSchedulableSession(
    UpdateSchedulableSessionEvent event,
    Emitter<SchedulableSessionState> emit,
  ) async {
    emit(SchedulableSessionLoading());

    final result = await _updateSchedulableSession(UpdateSchedulableSessionParams(
      schedulableSession: event.schedulableSession,
    ));

    result.fold(
      (failure) => emit(SchedulableSessionError(message: failure.message)),
      (_) {
        // Reload sessions after update
        add(LoadSchedulableSessions(instructorId: event.schedulableSession.instructorId));
      },
    );
  }

  Future<void> _onDeleteSchedulableSession(
    DeleteSchedulableSessionEvent event,
    Emitter<SchedulableSessionState> emit,
  ) async {
    emit(SchedulableSessionLoading());

    final result = await _deleteSchedulableSession(DeleteSchedulableSessionParams(
      id: event.id,
    ));

    result.fold(
      (failure) => emit(SchedulableSessionError(message: failure.message)),
      (_) {
        // Reload sessions after deletion
        if (state is SchedulableSessionLoaded) {
          final currentSessions = (state as SchedulableSessionLoaded).sessions;
          final instructorId = currentSessions.isNotEmpty ? currentSessions.first.instructorId : '';
          if (instructorId.isNotEmpty) {
            add(LoadSchedulableSessions(instructorId: instructorId));
          }
        }
      },
    );
  }
}
