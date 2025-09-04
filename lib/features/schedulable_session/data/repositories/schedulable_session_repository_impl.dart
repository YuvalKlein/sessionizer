import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';
import 'package:myapp/features/schedulable_session/domain/repositories/schedulable_session_repository.dart';
import 'package:myapp/features/schedulable_session/data/datasources/schedulable_session_remote_data_source.dart';
import 'package:myapp/features/schedulable_session/data/models/schedulable_session_model.dart';

class SchedulableSessionRepositoryImpl implements SchedulableSessionRepository {
  final SchedulableSessionRemoteDataSource _remoteDataSource;

  SchedulableSessionRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<SchedulableSessionEntity>> getSchedulableSessions(String instructorId) {
    return _remoteDataSource.getSchedulableSessions(instructorId);
  }

  @override
  Future<Either<Failure, SchedulableSessionEntity>> getSchedulableSession(String id) async {
    try {
      final session = await _remoteDataSource.getSchedulableSession(id);
      return Right(session);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SchedulableSessionEntity>> createSchedulableSession(SchedulableSessionEntity schedulableSession) async {
    try {
      final sessionModel = SchedulableSessionModel.fromEntity(schedulableSession);
      final createdSession = await _remoteDataSource.createSchedulableSession(sessionModel);
      return Right(createdSession);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SchedulableSessionEntity>> updateSchedulableSession(SchedulableSessionEntity schedulableSession) async {
    try {
      final sessionModel = SchedulableSessionModel.fromEntity(schedulableSession);
      final updatedSession = await _remoteDataSource.updateSchedulableSession(sessionModel);
      return Right(updatedSession);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSchedulableSession(String id) async {
    try {
      await _remoteDataSource.deleteSchedulableSession(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
