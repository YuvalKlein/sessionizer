import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/notification/domain/repositories/notification_repository.dart';

class SendBookingReminder {
  final NotificationRepository _repository;

  SendBookingReminder(this._repository);

  Future<Either<Failure, void>> call({
    required String bookingId,
    required int hoursBefore,
  }) async {
    return await _repository.sendBookingReminder(bookingId, hoursBefore);
  }
}







