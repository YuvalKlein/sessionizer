import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/usecases/usecase.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';
import 'package:myapp/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateScheduleUseCase implements UseCase<void, UpdateScheduleParams> {
  final ScheduleRepository repository;

  UpdateScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateScheduleParams params) async {
    return await repository.updateScheduleEntity(params.schedule);
  }
}

class UpdateScheduleParams {
  final ScheduleEntity schedule;

  UpdateScheduleParams({required this.schedule});
}
