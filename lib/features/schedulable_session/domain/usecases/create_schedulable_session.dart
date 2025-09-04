import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';
import 'package:myapp/features/schedulable_session/domain/repositories/schedulable_session_repository.dart';

class CreateSchedulableSession implements UseCase<SchedulableSessionEntity, CreateSchedulableSessionParams> {
  final SchedulableSessionRepository _repository;

  CreateSchedulableSession(this._repository);

  @override
  Future<Either<Failure, SchedulableSessionEntity>> call(CreateSchedulableSessionParams params) async {
    return await _repository.createSchedulableSession(params.schedulableSession);
  }
}

class CreateSchedulableSessionParams extends Equatable {
  final SchedulableSessionEntity schedulableSession;

  const CreateSchedulableSessionParams({required this.schedulableSession});

  @override
  List<Object> get props => [schedulableSession];
}
