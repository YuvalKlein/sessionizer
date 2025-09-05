import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/location/domain/repositories/location_repository.dart';

class DeleteLocation implements UseCase<void, DeleteLocationParams> {
  final LocationRepository _repository;

  DeleteLocation(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteLocationParams params) async {
    return await _repository.deleteLocation(params.id);
  }
}

class DeleteLocationParams extends Equatable {
  final String id;

  const DeleteLocationParams({required this.id});

  @override
  List<Object> get props => [id];
}
