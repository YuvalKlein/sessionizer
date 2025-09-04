import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';
import 'package:myapp/features/schedulable_session/domain/repositories/schedulable_session_repository.dart';

class GetSchedulableSessions implements UseCase<List<SchedulableSessionEntity>, GetSchedulableSessionsParams> {
  final SchedulableSessionRepository _repository;

  GetSchedulableSessions(this._repository);

  @override
  Future<Either<Failure, List<SchedulableSessionEntity>>> call(GetSchedulableSessionsParams params) async {
    try {
      final sessions = await _repository.getSchedulableSessions(params.instructorId).first;
      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure('Failed to load schedulable sessions: $e'));
    }
  }
}

class GetSchedulableSessionsParams extends Equatable {
  final String instructorId;

  const GetSchedulableSessionsParams({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}
