import 'package:myapp/core/utils/typedef.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';

abstract class BookableSessionRepository {
  Stream<List<BookableSessionEntity>> getBookableSessions(String instructorId);
  Stream<List<BookableSessionEntity>> getAllBookableSessions();
  ResultFuture<BookableSessionEntity> getBookableSession(String id);
  ResultFuture<BookableSessionEntity> createBookableSession(BookableSessionEntity bookableSession);
  ResultFuture<BookableSessionEntity> updateBookableSession(BookableSessionEntity bookableSession);
  ResultVoid deleteBookableSession(String id);
}
