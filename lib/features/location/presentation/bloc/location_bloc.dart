import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/location/domain/usecases/create_location.dart';
import 'package:myapp/features/location/domain/usecases/delete_location.dart';
import 'package:myapp/features/location/domain/usecases/get_locations.dart';
import 'package:myapp/features/location/domain/usecases/get_locations_by_instructor.dart';
import 'package:myapp/features/location/domain/usecases/update_location.dart';
import 'package:myapp/features/location/presentation/bloc/location_event.dart';
import 'package:myapp/features/location/presentation/bloc/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GetLocations _getLocations;
  final GetLocationsByInstructor _getLocationsByInstructor;
  final CreateLocation _createLocation;
  final UpdateLocation _updateLocation;
  final DeleteLocation _deleteLocation;

  LocationBloc({
    required GetLocations getLocations,
    required GetLocationsByInstructor getLocationsByInstructor,
    required CreateLocation createLocation,
    required UpdateLocation updateLocation,
    required DeleteLocation deleteLocation,
  })  : _getLocations = getLocations,
        _getLocationsByInstructor = getLocationsByInstructor,
        _createLocation = createLocation,
        _updateLocation = updateLocation,
        _deleteLocation = deleteLocation,
        super(LocationInitial()) {
    on<LoadLocations>(_onLoadLocations);
    on<LoadLocationsByInstructor>(_onLoadLocationsByInstructor);
    on<CreateLocationEvent>(_onCreateLocation);
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<DeleteLocationEvent>(_onDeleteLocation);
  }

  Future<void> _onLoadLocations(
    LoadLocations event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await _getLocations(NoParams());

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (locations) => emit(LocationLoaded(locations: locations)),
    );
  }

  Future<void> _onLoadLocationsByInstructor(
    LoadLocationsByInstructor event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await _getLocationsByInstructor(GetLocationsByInstructorParams(instructorId: event.instructorId));

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (locations) => emit(LocationLoaded(locations: locations)),
    );
  }

  Future<void> _onCreateLocation(
    CreateLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await _createLocation(CreateLocationParams(location: event.location));

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (location) {
        AppLogger.blocEvent('LocationBloc', 'CreateLocationEvent', data: {'locationId': location.id});
        add(LoadLocations()); // Reload locations
      },
    );
  }

  Future<void> _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await _updateLocation(UpdateLocationParams(location: event.location));

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (location) {
        AppLogger.blocEvent('LocationBloc', 'UpdateLocationEvent', data: {'locationId': location.id});
        add(LoadLocations()); // Reload locations
      },
    );
  }

  Future<void> _onDeleteLocation(
    DeleteLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await _deleteLocation(DeleteLocationParams(id: event.id));

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (_) {
        AppLogger.blocEvent('LocationBloc', 'DeleteLocationEvent', data: {'locationId': event.id});
        add(LoadLocationsByInstructor(instructorId: event.instructorId)); // Reload instructor's locations
      },
    );
  }
}
