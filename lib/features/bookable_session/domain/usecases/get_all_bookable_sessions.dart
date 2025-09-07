import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';
import 'package:myapp/features/bookable_session/domain/repositories/bookable_session_repository.dart';

class GetAllBookableSessions implements UseCase<List<BookableSessionEntity>, NoParams> {
  final BookableSessionRepository _repository;

  GetAllBookableSessions(this._repository);

  @override
  Future<Either<Failure, List<BookableSessionEntity>>> call(NoParams params) async {
    try {
      final sessions = await _repository.getAllBookableSessions().first;
      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure('Failed to load all bookable sessions: $e'));
    }
  }
}
