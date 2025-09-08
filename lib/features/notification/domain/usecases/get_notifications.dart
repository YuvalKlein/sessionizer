import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/notification/domain/entities/notification_entity.dart';
import 'package:myapp/features/notification/domain/repositories/notification_repository.dart';

class GetNotifications implements UseCase<List<NotificationEntity>, String> {
  final NotificationRepository _repository;

  GetNotifications(this._repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(String userId) async {
    return await _repository.getNotifications(userId);
  }
}





