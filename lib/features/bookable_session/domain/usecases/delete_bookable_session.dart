import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/bookable_session/domain/repositories/bookable_session_repository.dart';

class DeleteBookableSession implements UseCase<void, DeleteBookableSessionParams> {
  final BookableSessionRepository _repository;

  DeleteBookableSession(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteBookableSessionParams params) async {
    return await _repository.deleteBookableSession(params.id);
  }
}

class DeleteBookableSessionParams extends Equatable {
  final String id;

  const DeleteBookableSessionParams({required this.id});

  @override
  List<Object> get props => [id];
}

