import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';
import 'package:myapp/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:myapp/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:myapp/features/schedule/data/models/schedule_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource _remoteDataSource;

  ScheduleRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<ScheduleEntity>> getSchedules(String instructorId) {
    return _remoteDataSource.getSchedules(instructorId);
  }

  @override
  Future<Either<Failure, ScheduleEntity>> getSchedule(String scheduleId) async {
    try {
      final schedule = await _remoteDataSource.getSchedule(scheduleId);
      if (schedule != null) {
        return Right(schedule);
      } else {
        return const Left(ServerFailure('Schedule not found'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, ScheduleEntity>> getScheduleById(String scheduleId) async {
    try {
      final schedule = await _remoteDataSource.getSchedule(scheduleId);
      if (schedule != null) {
        return Right(schedule);
      } else {
        return const Left(ServerFailure('Schedule not found'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, ScheduleEntity>> createSchedule(ScheduleEntity schedule) async {
    try {
      final scheduleModel = await _remoteDataSource.createSchedule(
        ScheduleModel.fromEntity(schedule),
      );
      return Right(scheduleModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, ScheduleEntity>> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      final schedule = await _remoteDataSource.updateSchedule(scheduleId, data);
      return Right(schedule);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateScheduleEntity(ScheduleEntity schedule) async {
    try {
      await _remoteDataSource.updateScheduleEntity(schedule);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSchedule(String scheduleId) async {
    try {
      await _remoteDataSource.deleteSchedule(scheduleId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultSchedule(String instructorId, String scheduleId, bool isDefault) async {
    try {
      await _remoteDataSource.setDefaultSchedule(instructorId, scheduleId, isDefault);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unsetAllDefaultSchedules() async {
    try {
      await _remoteDataSource.unsetAllDefaultSchedules();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
