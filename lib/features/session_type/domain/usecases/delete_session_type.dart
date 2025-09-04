import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/session_type/domain/repositories/session_type_repository.dart';

class DeleteSessionType implements UseCase<void, DeleteSessionTypeParams> {
  final SessionTypeRepository _repository;

  DeleteSessionType(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteSessionTypeParams params) async {
    return await _repository.deleteSessionType(params.id);
  }
}

class DeleteSessionTypeParams extends Equatable {
  final String id;

  const DeleteSessionTypeParams({required this.id});

  @override
  List<Object> get props => [id];
}
