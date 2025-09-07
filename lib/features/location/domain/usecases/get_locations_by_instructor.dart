import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';
import 'package:myapp/features/location/domain/repositories/location_repository.dart';

class GetLocationsByInstructor implements UseCase<List<LocationEntity>, GetLocationsByInstructorParams> {
  final LocationRepository _repository;

  GetLocationsByInstructor(this._repository);

  @override
  Future<Either<Failure, List<LocationEntity>>> call(GetLocationsByInstructorParams params) async {
    try {
      final locations = await _repository.getLocationsByInstructor(params.instructorId).first;
      return Right(locations);
    } catch (e) {
      return Left(ServerFailure('Failed to load locations: $e'));
    }
  }
}

class GetLocationsByInstructorParams extends Equatable {
  final String instructorId;

  const GetLocationsByInstructorParams({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}
