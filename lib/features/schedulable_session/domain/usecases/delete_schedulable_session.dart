import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedulable_session/domain/repositories/schedulable_session_repository.dart';

class DeleteSchedulableSession implements UseCase<void, DeleteSchedulableSessionParams> {
  final SchedulableSessionRepository _repository;

  DeleteSchedulableSession(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteSchedulableSessionParams params) async {
    return await _repository.deleteSchedulableSession(params.id);
  }
}

class DeleteSchedulableSessionParams extends Equatable {
  final String id;

  const DeleteSchedulableSessionParams({required this.id});

  @override
  List<Object> get props => [id];
}
