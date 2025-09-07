import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/session_type/data/models/session_type_model.dart';

abstract class SessionTypeRemoteDataSource {
  Stream<List<SessionTypeModel>> getSessionTypes();
  Future<SessionTypeModel> getSessionType(String id);
  Future<SessionTypeModel> createSessionType(SessionTypeModel sessionType);
  Future<SessionTypeModel> updateSessionType(SessionTypeModel sessionType);
  Future<void> deleteSessionType(String id);
}

class SessionTypeRemoteDataSourceImpl implements SessionTypeRemoteDataSource {
  final FirebaseFirestore _firestore;

  SessionTypeRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<SessionTypeModel>> getSessionTypes() {
    // Try both collections to handle migration from old format
    return Stream.fromFuture(_getAllSessionTypes());
  }

  Future<List<SessionTypeModel>> _getAllSessionTypes() async {
    final List<SessionTypeModel> allSessionTypes = [];
    
    try {
      // Get from new collection (session_types)
      final newSnapshot = await _firestore
          .collection('sessionizer')
          .doc('session_types')
          .collection('session_types')
          .get();
      
      for (final doc in newSnapshot.docs) {
        try {
          allSessionTypes.add(SessionTypeModel.fromMap({...doc.data(), 'id': doc.id}));
        } catch (e) {
          AppLogger.error('Error parsing new session type ${doc.id}: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Error getting new session types: $e');
    }
    
    try {
      // Get from old collection (sessionTypes) and convert
      final oldSnapshot = await _firestore
          .collection('sessionTypes')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (final doc in oldSnapshot.docs) {
        try {
          final data = doc.data();
          // Convert old format to new format
          final convertedData = {
                      'id': doc.id,
          'title': data['title'] ?? data['name'] ?? '',
          'notifyCancelation': data['notifyCancelation'] ?? false,
            'createdTime': data['createdTime'] ?? DateTime.now().millisecondsSinceEpoch,
            'duration': data['duration'] ?? data['durationMinutes'] ?? 60,
            'durationUnit': data['durationUnit'] ?? 'minutes',
            'details': data['details'] ?? data['description'] ?? '',
            'idCreatedBy': data['idCreatedBy'] ?? '',
            'maxPlayers': data['maxPlayers'] ?? data['maxParticipants'] ?? 1,
            'minPlayers': data['minPlayers'] ?? 1,
            'showParticipants': data['showParticipants'] ?? true,
            'category': data['category'] ?? 'tennis',
            'price': data['price'] ?? 0,
          };
          allSessionTypes.add(SessionTypeModel.fromMap(convertedData));
        } catch (e) {
          AppLogger.error('Error converting old session type ${doc.id}: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Error getting old session types: $e');
    }
    
    return allSessionTypes;
  }

  @override
  Future<SessionTypeModel> getSessionType(String id) async {
    final doc = await _firestore.collection('sessionizer').doc('session_types').collection('session_types').doc(id).get();
    if (!doc.exists) {
      throw Exception('Session type not found');
    }
    return SessionTypeModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<SessionTypeModel> createSessionType(SessionTypeModel sessionType) async {
    final docRef = await _firestore.collection('sessionizer').doc('session_types').collection('session_types').add(sessionType.toMap());
    final createdSessionType = sessionType.copyWith(id: docRef.id);
    await docRef.set(createdSessionType.toMap());
    return createdSessionType;
  }

  @override
  Future<SessionTypeModel> updateSessionType(SessionTypeModel sessionType) async {
    await _firestore
        .collection('sessionizer')
        .doc('session_types')
        .collection('session_types')
        .doc(sessionType.id)
        .update(sessionType.toMap());
    return sessionType;
  }

  @override
  Future<void> deleteSessionType(String id) async {
    try {
      // Try new collection first
      await _firestore.collection('sessionizer').doc('session_types').collection('session_types').doc(id).delete();
    } catch (e) {
      try {
        // Try old collection if new one fails
        await _firestore.collection('sessionTypes').doc(id).delete();
      } catch (e2) {
        throw Exception('Session type not found in either collection');
      }
    }
  }
}
