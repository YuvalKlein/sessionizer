import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';
import 'package:myapp/features/bookable_session/domain/repositories/bookable_session_repository.dart';

class UpdateBookableSession implements UseCase<BookableSessionEntity, UpdateBookableSessionParams> {
  final BookableSessionRepository _repository;

  UpdateBookableSession(this._repository);

  @override
  Future<Either<Failure, BookableSessionEntity>> call(UpdateBookableSessionParams params) async {
    return await _repository.updateBookableSession(params.bookableSession);
  }
}

class UpdateBookableSessionParams extends Equatable {
  final BookableSessionEntity bookableSession;

  const UpdateBookableSessionParams({required this.bookableSession});

  @override
  List<Object> get props => [bookableSession];
}

