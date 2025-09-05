import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';
import 'package:myapp/features/location/domain/repositories/location_repository.dart';

class CreateLocation implements UseCase<LocationEntity, CreateLocationParams> {
  final LocationRepository _repository;

  CreateLocation(this._repository);

  @override
  Future<Either<Failure, LocationEntity>> call(CreateLocationParams params) async {
    return await _repository.createLocation(params.location);
  }
}

class CreateLocationParams extends Equatable {
  final LocationEntity location;

  const CreateLocationParams({required this.location});

  @override
  List<Object> get props => [location];
}
