import 'package:equatable/equatable.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';

abstract class BookableSessionEvent extends Equatable {
  const BookableSessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookableSessions extends BookableSessionEvent {
  final String instructorId;

  const LoadBookableSessions({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}

class LoadAllBookableSessions extends BookableSessionEvent {
  const LoadAllBookableSessions();
}

class CreateBookableSessionEvent extends BookableSessionEvent {
  final BookableSessionEntity bookableSession;

  const CreateBookableSessionEvent({required this.bookableSession});

  @override
  List<Object> get props => [bookableSession];
}

class UpdateBookableSessionEvent extends BookableSessionEvent {
  final BookableSessionEntity bookableSession;

  const UpdateBookableSessionEvent({required this.bookableSession});

  @override
  List<Object> get props => [bookableSession];
}

class DeleteBookableSessionEvent extends BookableSessionEvent {
  final String id;

  const DeleteBookableSessionEvent({required this.id});

  @override
  List<Object> get props => [id];
}

