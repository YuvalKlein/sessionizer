import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/bookable_session/domain/usecases/get_bookable_sessions.dart';
import 'package:myapp/features/bookable_session/domain/usecases/get_all_bookable_sessions.dart';
import 'package:myapp/features/bookable_session/domain/usecases/create_bookable_session.dart';
import 'package:myapp/features/bookable_session/domain/usecases/update_bookable_session.dart';
import 'package:myapp/features/bookable_session/domain/usecases/delete_bookable_session.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_event.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_state.dart';
import 'package:myapp/core/utils/usecase.dart';

class BookableSessionBloc extends Bloc<BookableSessionEvent, BookableSessionState> {
  final GetBookableSessions _getBookableSessions;
  final GetAllBookableSessions _getAllBookableSessions;
  final CreateBookableSession _createBookableSession;
  final UpdateBookableSession _updateBookableSession;
  final DeleteBookableSession _deleteBookableSession;

  BookableSessionBloc({
    required GetBookableSessions getBookableSessions,
    required GetAllBookableSessions getAllBookableSessions,
    required CreateBookableSession createBookableSession,
    required UpdateBookableSession updateBookableSession,
    required DeleteBookableSession deleteBookableSession,
  })  : _getBookableSessions = getBookableSessions,
        _getAllBookableSessions = getAllBookableSessions,
        _createBookableSession = createBookableSession,
        _updateBookableSession = updateBookableSession,
        _deleteBookableSession = deleteBookableSession,
        super(BookableSessionInitial()) {
    on<LoadBookableSessions>(_onLoadBookableSessions);
    on<LoadAllBookableSessions>(_onLoadAllBookableSessions);
    on<CreateBookableSessionEvent>(_onCreateBookableSession);
    on<UpdateBookableSessionEvent>(_onUpdateBookableSession);
    on<DeleteBookableSessionEvent>(_onDeleteBookableSession);
  }

  Future<void> _onLoadBookableSessions(
    LoadBookableSessions event,
    Emitter<BookableSessionState> emit,
  ) async {
    emit(BookableSessionLoading());

    final result = await _getBookableSessions(GetBookableSessionsParams(
      instructorId: event.instructorId,
    ));

    result.fold(
      (failure) => emit(BookableSessionError(message: failure.message)),
      (sessions) => emit(BookableSessionLoaded(sessions: sessions)),
    );
  }

  Future<void> _onLoadAllBookableSessions(
    LoadAllBookableSessions event,
    Emitter<BookableSessionState> emit,
  ) async {
    emit(BookableSessionLoading());

    final result = await _getAllBookableSessions(NoParams());

    result.fold(
      (failure) => emit(BookableSessionError(message: failure.message)),
      (sessions) => emit(BookableSessionLoaded(sessions: sessions)),
    );
  }

  Future<void> _onCreateBookableSession(
    CreateBookableSessionEvent event,
    Emitter<BookableSessionState> emit,
  ) async {
    emit(BookableSessionLoading());

    final result = await _createBookableSession(CreateBookableSessionParams(
      bookableSession: event.bookableSession,
    ));

    result.fold(
      (failure) => emit(BookableSessionError(message: failure.message)),
      (_) {
        // Reload sessions after creation
        add(LoadBookableSessions(instructorId: event.bookableSession.instructorId));
      },
    );
  }

  Future<void> _onUpdateBookableSession(
    UpdateBookableSessionEvent event,
    Emitter<BookableSessionState> emit,
  ) async {
    emit(BookableSessionLoading());

    final result = await _updateBookableSession(UpdateBookableSessionParams(
      bookableSession: event.bookableSession,
    ));

    result.fold(
      (failure) => emit(BookableSessionError(message: failure.message)),
      (_) {
        // Reload sessions after update
        add(LoadBookableSessions(instructorId: event.bookableSession.instructorId));
      },
    );
  }

  Future<void> _onDeleteBookableSession(
    DeleteBookableSessionEvent event,
    Emitter<BookableSessionState> emit,
  ) async {
    emit(BookableSessionLoading());

    final result = await _deleteBookableSession(DeleteBookableSessionParams(
      id: event.id,
    ));

    result.fold(
      (failure) => emit(BookableSessionError(message: failure.message)),
      (_) {
        // Reload sessions after deletion
        if (state is BookableSessionLoaded) {
          final currentSessions = (state as BookableSessionLoaded).sessions;
          final instructorId = currentSessions.isNotEmpty ? currentSessions.first.instructorId : '';
          if (instructorId.isNotEmpty) {
            add(LoadBookableSessions(instructorId: instructorId));
          }
        }
      },
    );
  }
}

