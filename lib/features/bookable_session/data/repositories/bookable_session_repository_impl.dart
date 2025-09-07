import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';
import 'package:myapp/features/bookable_session/domain/repositories/bookable_session_repository.dart';
import 'package:myapp/features/bookable_session/data/datasources/bookable_session_remote_data_source.dart';
import 'package:myapp/features/bookable_session/data/models/bookable_session_model.dart';

class BookableSessionRepositoryImpl implements BookableSessionRepository {
  final BookableSessionRemoteDataSource _remoteDataSource;

  BookableSessionRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<BookableSessionEntity>> getBookableSessions(String instructorId) {
    return _remoteDataSource.getBookableSessions(instructorId);
  }

  @override
  Stream<List<BookableSessionEntity>> getAllBookableSessions() {
    return _remoteDataSource.getAllBookableSessions();
  }

  @override
  Future<Either<Failure, BookableSessionEntity>> getBookableSession(String id) async {
    try {
      final session = await _remoteDataSource.getBookableSession(id);
      return Right(session);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, BookableSessionEntity>> createBookableSession(BookableSessionEntity bookableSession) async {
    try {
      final sessionModel = BookableSessionModel.fromEntity(bookableSession);
      final createdSession = await _remoteDataSource.createBookableSession(sessionModel);
      return Right(createdSession);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, BookableSessionEntity>> updateBookableSession(BookableSessionEntity bookableSession) async {
    try {
      final sessionModel = BookableSessionModel.fromEntity(bookableSession);
      final updatedSession = await _remoteDataSource.updateBookableSession(sessionModel);
      return Right(updatedSession);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBookableSession(String id) async {
    try {
      await _remoteDataSource.deleteBookableSession(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
