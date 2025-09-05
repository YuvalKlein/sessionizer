import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';
import 'package:myapp/features/location/domain/repositories/location_repository.dart';

class UpdateLocation implements UseCase<LocationEntity, UpdateLocationParams> {
  final LocationRepository _repository;

  UpdateLocation(this._repository);

  @override
  Future<Either<Failure, LocationEntity>> call(UpdateLocationParams params) async {
    return await _repository.updateLocation(params.location);
  }
}

class UpdateLocationParams extends Equatable {
  final LocationEntity location;

  const UpdateLocationParams({required this.location});

  @override
  List<Object> get props => [location];
}
