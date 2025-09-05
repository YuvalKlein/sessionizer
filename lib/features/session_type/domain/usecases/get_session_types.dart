import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/features/session_type/domain/repositories/session_type_repository.dart';

class GetSessionTypes implements UseCase<List<SessionTypeEntity>, NoParams> {
  final SessionTypeRepository _repository;

  GetSessionTypes(this._repository);

  @override
  Future<Either<Failure, List<SessionTypeEntity>>> call(NoParams params) async {
    try {
      final sessionTypes = await _repository.getSessionTypes().first;
      return Right(sessionTypes);
    } catch (e) {
      return Left(ServerFailure('Failed to load session types: $e'));
    }
  }
}
