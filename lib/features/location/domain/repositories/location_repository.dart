import 'package:myapp/core/utils/typedef.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';

abstract class LocationRepository {
  Stream<List<LocationEntity>> getLocations();
  Stream<List<LocationEntity>> getLocationsByInstructor(String instructorId);
  ResultFuture<LocationEntity> getLocation(String id);
  ResultFuture<LocationEntity> createLocation(LocationEntity location);
  ResultFuture<LocationEntity> updateLocation(LocationEntity location);
  ResultVoid deleteLocation(String id);
}
