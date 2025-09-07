import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';
import 'package:myapp/features/bookable_session/domain/repositories/bookable_session_repository.dart';

class CreateBookableSession implements UseCase<BookableSessionEntity, CreateBookableSessionParams> {
  final BookableSessionRepository _repository;

  CreateBookableSession(this._repository);

  @override
  Future<Either<Failure, BookableSessionEntity>> call(CreateBookableSessionParams params) async {
    return await _repository.createBookableSession(params.bookableSession);
  }
}

class CreateBookableSessionParams extends Equatable {
  final BookableSessionEntity bookableSession;

  const CreateBookableSessionParams({required this.bookableSession});

  @override
  List<Object> get props => [bookableSession];
}

