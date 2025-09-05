import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';

abstract class ScheduleRepository {
  Stream<List<ScheduleEntity>> getSchedules(String instructorId);
  Future<Either<Failure, ScheduleEntity>> getSchedule(String scheduleId);
  Future<Either<Failure, ScheduleEntity>> getScheduleById(String scheduleId);
  Future<Either<Failure, ScheduleEntity>> createSchedule(ScheduleEntity schedule);
  Future<Either<Failure, ScheduleEntity>> updateSchedule(String scheduleId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteSchedule(String scheduleId);
  Future<Either<Failure, void>> setDefaultSchedule(String instructorId, String scheduleId, bool isDefault);
  Future<Either<Failure, void>> unsetAllDefaultSchedules();
}
