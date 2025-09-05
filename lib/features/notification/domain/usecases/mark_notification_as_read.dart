import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/notification/domain/repositories/notification_repository.dart';

class MarkNotificationAsRead implements UseCase<void, String> {
  final NotificationRepository _repository;

  MarkNotificationAsRead(this._repository);

  @override
  Future<Either<Failure, void>> call(String notificationId) async {
    return await _repository.markAsRead(notificationId);
  }
}

