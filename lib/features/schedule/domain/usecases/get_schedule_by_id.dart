import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';
import 'package:myapp/features/schedule/domain/repositories/schedule_repository.dart';

class GetScheduleById implements UseCase<ScheduleEntity, String> {
  final ScheduleRepository _repository;

  GetScheduleById(this._repository);

  @override
  Future<Either<Failure, ScheduleEntity>> call(String scheduleId) async {
    return await _repository.getScheduleById(scheduleId);
  }
}
