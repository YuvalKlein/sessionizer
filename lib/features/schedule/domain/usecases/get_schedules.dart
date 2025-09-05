import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';
import 'package:myapp/features/schedule/domain/repositories/schedule_repository.dart';

class GetSchedules implements UseCase<List<ScheduleEntity>, GetSchedulesParams> {
  final ScheduleRepository _repository;

  GetSchedules(this._repository);

  @override
  Future<Either<Failure, List<ScheduleEntity>>> call(GetSchedulesParams params) async {
    try {
      final schedules = await _repository.getSchedules(params.instructorId).first;
      return Right(schedules);
    } catch (e) {
      return Left(ServerFailure('Failed to load schedules: $e'));
    }
  }
}

class GetSchedulesParams extends Equatable {
  final String instructorId;

  const GetSchedulesParams({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}
