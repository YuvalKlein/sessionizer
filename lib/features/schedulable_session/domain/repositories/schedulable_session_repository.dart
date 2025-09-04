import 'package:myapp/core/utils/typedef.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';

abstract class SchedulableSessionRepository {
  Stream<List<SchedulableSessionEntity>> getSchedulableSessions(String instructorId);
  ResultFuture<SchedulableSessionEntity> getSchedulableSession(String id);
  ResultFuture<SchedulableSessionEntity> createSchedulableSession(SchedulableSessionEntity schedulableSession);
  ResultFuture<SchedulableSessionEntity> updateSchedulableSession(SchedulableSessionEntity schedulableSession);
  ResultVoid deleteSchedulableSession(String id);
}
