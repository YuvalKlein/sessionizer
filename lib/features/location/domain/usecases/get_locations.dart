import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';
import 'package:myapp/features/location/domain/repositories/location_repository.dart';

class GetLocations implements UseCase<List<LocationEntity>, NoParams> {
  final LocationRepository _repository;

  GetLocations(this._repository);

  @override
  Future<Either<Failure, List<LocationEntity>>> call(NoParams params) async {
    try {
      final locations = await _repository.getLocations().first;
      return Right(locations);
    } catch (e) {
      return Left(ServerFailure('Failed to load locations: $e'));
    }
  }
}
