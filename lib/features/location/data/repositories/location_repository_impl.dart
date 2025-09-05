import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';
import 'package:myapp/features/location/domain/repositories/location_repository.dart';
import 'package:myapp/features/location/data/datasources/location_remote_data_source.dart';
import 'package:myapp/features/location/data/models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource _remoteDataSource;

  LocationRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<LocationEntity>> getLocations() {
    return _remoteDataSource.getLocations();
  }

  @override
  Future<Either<Failure, LocationEntity>> getLocation(String id) async {
    try {
      final location = await _remoteDataSource.getLocation(id);
      return Right(location);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> createLocation(LocationEntity location) async {
    try {
      final locationModel = LocationModel.fromEntity(location);
      final createdLocation = await _remoteDataSource.createLocation(locationModel);
      return Right(createdLocation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> updateLocation(LocationEntity location) async {
    try {
      final locationModel = LocationModel.fromEntity(location);
      final updatedLocation = await _remoteDataSource.updateLocation(locationModel);
      return Right(updatedLocation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocation(String id) async {
    try {
      await _remoteDataSource.deleteLocation(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
