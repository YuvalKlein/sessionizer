import 'package:equatable/equatable.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';

abstract class BookableSessionState extends Equatable {
  const BookableSessionState();

  @override
  List<Object?> get props => [];
}

class BookableSessionInitial extends BookableSessionState {}

class BookableSessionLoading extends BookableSessionState {}

class BookableSessionLoaded extends BookableSessionState {
  final List<BookableSessionEntity> sessions;

  const BookableSessionLoaded({required this.sessions});

  @override
  List<Object> get props => [sessions];
}

class BookableSessionError extends BookableSessionState {
  final String message;

  const BookableSessionError({required this.message});

  @override
  List<Object> get props => [message];
}

