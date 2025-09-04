import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';
import 'package:myapp/features/schedule/domain/repositories/schedule_repository.dart';

class CreateSchedule implements UseCase<ScheduleEntity, CreateScheduleParams> {
  final ScheduleRepository _repository;

  CreateSchedule(this._repository);

  @override
  Future<Either<Failure, ScheduleEntity>> call(CreateScheduleParams params) async {
    return await _repository.createSchedule(params.schedule);
  }
}

class CreateScheduleParams extends Equatable {
  final ScheduleEntity schedule;

  const CreateScheduleParams({required this.schedule});

  @override
  List<Object> get props => [schedule];
}
