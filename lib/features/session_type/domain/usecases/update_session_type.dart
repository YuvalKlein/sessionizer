import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/features/session_type/domain/repositories/session_type_repository.dart';

class UpdateSessionType implements UseCase<SessionTypeEntity, UpdateSessionTypeParams> {
  final SessionTypeRepository _repository;

  UpdateSessionType(this._repository);

  @override
  Future<Either<Failure, SessionTypeEntity>> call(UpdateSessionTypeParams params) async {
    return await _repository.updateSessionType(params.sessionType);
  }
}

class UpdateSessionTypeParams extends Equatable {
  final SessionTypeEntity sessionType;

  const UpdateSessionTypeParams({required this.sessionType});

  @override
  List<Object> get props => [sessionType];
}
