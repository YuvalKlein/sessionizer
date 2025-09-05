import 'package:equatable/equatable.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LoadLocations extends LocationEvent {}

class CreateLocationEvent extends LocationEvent {
  final LocationEntity location;

  const CreateLocationEvent({required this.location});

  @override
  List<Object> get props => [location];
}

class UpdateLocationEvent extends LocationEvent {
  final LocationEntity location;

  const UpdateLocationEvent({required this.location});

  @override
  List<Object> get props => [location];
}

class DeleteLocationEvent extends LocationEvent {
  final String id;

  const DeleteLocationEvent({required this.id});

  @override
  List<Object> get props => [id];
}
