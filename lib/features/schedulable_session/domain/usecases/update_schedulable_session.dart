import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';
import 'package:myapp/features/schedulable_session/domain/repositories/schedulable_session_repository.dart';

class UpdateSchedulableSession implements UseCase<SchedulableSessionEntity, UpdateSchedulableSessionParams> {
  final SchedulableSessionRepository _repository;

  UpdateSchedulableSession(this._repository);

  @override
  Future<Either<Failure, SchedulableSessionEntity>> call(UpdateSchedulableSessionParams params) async {
    return await _repository.updateSchedulableSession(params.schedulableSession);
  }
}

class UpdateSchedulableSessionParams extends Equatable {
  final SchedulableSessionEntity schedulableSession;

  const UpdateSchedulableSessionParams({required this.schedulableSession});

  @override
  List<Object> get props => [schedulableSession];
}
