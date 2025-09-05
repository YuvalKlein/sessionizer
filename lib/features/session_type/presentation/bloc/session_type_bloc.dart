import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/session_type/domain/usecases/get_session_types.dart';
import 'package:myapp/features/session_type/domain/usecases/create_session_type.dart';
import 'package:myapp/features/session_type/domain/usecases/update_session_type.dart';
import 'package:myapp/features/session_type/domain/usecases/delete_session_type.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_event.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_state.dart';
import 'package:myapp/core/utils/usecase.dart';

class SessionTypeBloc extends Bloc<SessionTypeEvent, SessionTypeState> {
  final GetSessionTypes _getSessionTypes;
  final CreateSessionType _createSessionType;
  final UpdateSessionType _updateSessionType;
  final DeleteSessionType _deleteSessionType;

  SessionTypeBloc({
    required GetSessionTypes getSessionTypes,
    required CreateSessionType createSessionType,
    required UpdateSessionType updateSessionType,
    required DeleteSessionType deleteSessionType,
  })  : _getSessionTypes = getSessionTypes,
        _createSessionType = createSessionType,
        _updateSessionType = updateSessionType,
        _deleteSessionType = deleteSessionType,
        super(SessionTypeInitial()) {
    on<LoadSessionTypes>(_onLoadSessionTypes);
    on<CreateSessionTypeEvent>(_onCreateSessionType);
    on<UpdateSessionTypeEvent>(_onUpdateSessionType);
    on<DeleteSessionTypeEvent>(_onDeleteSessionType);
  }

  Future<void> _onLoadSessionTypes(
    LoadSessionTypes event,
    Emitter<SessionTypeState> emit,
  ) async {
    emit(SessionTypeLoading());

    final result = await _getSessionTypes(NoParams());

    result.fold(
      (failure) => emit(SessionTypeError(message: failure.message)),
      (sessionTypes) => emit(SessionTypeLoaded(sessionTypes: sessionTypes)),
    );
  }

  Future<void> _onCreateSessionType(
    CreateSessionTypeEvent event,
    Emitter<SessionTypeState> emit,
  ) async {
    emit(SessionTypeLoading());

    final result = await _createSessionType(CreateSessionTypeParams(
      sessionType: event.sessionType,
    ));

    result.fold(
      (failure) => emit(SessionTypeError(message: failure.message)),
      (_) {
        // Reload session types after creation
        add(LoadSessionTypes());
      },
    );
  }

  Future<void> _onUpdateSessionType(
    UpdateSessionTypeEvent event,
    Emitter<SessionTypeState> emit,
  ) async {
    emit(SessionTypeLoading());

    final result = await _updateSessionType(UpdateSessionTypeParams(
      sessionType: event.sessionType,
    ));

    result.fold(
      (failure) => emit(SessionTypeError(message: failure.message)),
      (_) {
        // Reload session types after update
        add(LoadSessionTypes());
      },
    );
  }

  Future<void> _onDeleteSessionType(
    DeleteSessionTypeEvent event,
    Emitter<SessionTypeState> emit,
  ) async {
    emit(SessionTypeLoading());

    final result = await _deleteSessionType(DeleteSessionTypeParams(
      id: event.id,
    ));

    result.fold(
      (failure) => emit(SessionTypeError(message: failure.message)),
      (_) {
        // Reload session types after deletion
        add(LoadSessionTypes());
      },
    );
  }
}
