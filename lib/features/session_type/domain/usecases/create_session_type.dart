import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/features/session_type/domain/repositories/session_type_repository.dart';

class CreateSessionType implements UseCase<SessionTypeEntity, CreateSessionTypeParams> {
  final SessionTypeRepository _repository;

  CreateSessionType(this._repository);

  @override
  Future<Either<Failure, SessionTypeEntity>> call(CreateSessionTypeParams params) async {
    return await _repository.createSessionType(params.sessionType);
  }
}

class CreateSessionTypeParams extends Equatable {
  final SessionTypeEntity sessionType;

  const CreateSessionTypeParams({required this.sessionType});

  @override
  List<Object> get props => [sessionType];
}
