import 'package:myapp/core/utils/typedef.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';

abstract class SessionTypeRepository {
  Stream<List<SessionTypeEntity>> getSessionTypes();
  ResultFuture<SessionTypeEntity> getSessionType(String id);
  ResultFuture<SessionTypeEntity> createSessionType(SessionTypeEntity sessionType);
  ResultFuture<SessionTypeEntity> updateSessionType(SessionTypeEntity sessionType);
  ResultVoid deleteSessionType(String id);
}
