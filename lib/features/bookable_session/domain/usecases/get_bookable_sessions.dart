import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';
import 'package:myapp/features/bookable_session/domain/repositories/bookable_session_repository.dart';

class GetBookableSessions implements UseCase<List<BookableSessionEntity>, GetBookableSessionsParams> {
  final BookableSessionRepository _repository;

  GetBookableSessions(this._repository);

  @override
  Future<Either<Failure, List<BookableSessionEntity>>> call(GetBookableSessionsParams params) async {
    try {
      final sessions = await _repository.getBookableSessions(params.instructorId).first;
      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure('Failed to load bookable sessions: $e'));
    }
  }
}

class GetBookableSessionsParams extends Equatable {
  final String instructorId;

  const GetBookableSessionsParams({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}
