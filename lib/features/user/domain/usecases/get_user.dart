import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';

class GetUser implements UseCase<UserProfileEntity, GetUserParams> {
  final UserRepository _repository;

  GetUser(this._repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(GetUserParams params) async {
    return await _repository.getUserById(params.userId);
  }
}

class GetUserParams extends Equatable {
  final String userId;

  const GetUserParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
