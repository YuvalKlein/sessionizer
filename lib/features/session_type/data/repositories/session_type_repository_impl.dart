import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/features/session_type/domain/repositories/session_type_repository.dart';
import 'package:myapp/features/session_type/data/datasources/session_type_remote_data_source.dart';
import 'package:myapp/features/session_type/data/models/session_type_model.dart';

class SessionTypeRepositoryImpl implements SessionTypeRepository {
  final SessionTypeRemoteDataSource _remoteDataSource;

  SessionTypeRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<SessionTypeEntity>> getSessionTypes() {
    return _remoteDataSource.getSessionTypes();
  }

  @override
  Future<Either<Failure, SessionTypeEntity>> getSessionType(String id) async {
    try {
      final sessionType = await _remoteDataSource.getSessionType(id);
      return Right(sessionType);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionTypeEntity>> createSessionType(SessionTypeEntity sessionType) async {
    try {
      print('🔧 SessionTypeRepositoryImpl: Converting entity to model');
      final sessionTypeModel = SessionTypeModel.fromEntity(sessionType);
      print('🔧 SessionTypeRepositoryImpl: Model created, calling data source');
      print('  hasCancellationFee: ${sessionTypeModel.hasCancellationFee}');
      print('  cancellationTimeBefore: ${sessionTypeModel.cancellationTimeBefore}');
      print('  cancellationTimeUnit: ${sessionTypeModel.cancellationTimeUnit}');
      print('  cancellationFeeAmount: ${sessionTypeModel.cancellationFeeAmount}');
      print('  cancellationFeeType: ${sessionTypeModel.cancellationFeeType}');
      
      final createdSessionType = await _remoteDataSource.createSessionType(sessionTypeModel);
      print('🔧 SessionTypeRepositoryImpl: Data source call completed');
      return Right(createdSessionType);
    } on ServerException catch (e) {
      print('❌ SessionTypeRepositoryImpl: ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ SessionTypeRepositoryImpl: Unexpected error: $e');
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionTypeEntity>> updateSessionType(SessionTypeEntity sessionType) async {
    try {
      final sessionTypeModel = SessionTypeModel.fromEntity(sessionType);
      final updatedSessionType = await _remoteDataSource.updateSessionType(sessionTypeModel);
      return Right(updatedSessionType);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSessionType(String id) async {
    try {
      await _remoteDataSource.deleteSessionType(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
