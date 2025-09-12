import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/session_type/data/models/session_type_model.dart';
import 'package:myapp/core/config/firestore_collections.dart';

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
      // Get from new collection using FirestoreCollections
      final newSnapshot = await FirestoreCollections.sessionTypes.get();
      
      for (final doc in newSnapshot.docs) {
        try {
          allSessionTypes.add(SessionTypeModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}));
        } catch (e) {
          AppLogger.error('Error parsing new session type ${doc.id}: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Error getting new session types: $e');
    }
    
    try {
      // Get from old collection (sessionizer/sessionTypes/sessionTypes) and convert
      final oldSnapshot = await _firestore
          .collection('sessionizer')
          .doc('sessionTypes')
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
            // Cancellation Policy fields with defaults (new format as map)
            'cancellationPolicy': {
              'hasCancellationFee': data['hasCancellationFee'] ?? data['cancellationPolicy']?['hasCancellationFee'] ?? true,
              'cancellationTimeBefore': data['cancellationTimeBefore'] ?? data['cancellationPolicy']?['cancellationTimeBefore'] ?? 18,
              'cancellationTimeUnit': data['cancellationTimeUnit'] ?? data['cancellationPolicy']?['cancellationTimeUnit'] ?? 'hours',
              'cancellationFeeAmount': data['cancellationFeeAmount'] ?? data['cancellationPolicy']?['cancellationFeeAmount'] ?? 100,
              'cancellationFeeType': data['cancellationFeeType'] ?? data['cancellationPolicy']?['cancellationFeeType'] ?? '%',
            },
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
    final doc = await FirestoreCollections.sessionType(id).get();
    if (!doc.exists) {
      throw Exception('Session type not found');
    }
    return SessionTypeModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  @override
  Future<SessionTypeModel> createSessionType(SessionTypeModel sessionType) async {
    try {
      print('🔧 SessionTypeRemoteDataSource: Starting createSessionType');
      final dataToSave = sessionType.toMap();
      print('🔧 SessionTypeRemoteDataSource: Data to save: $dataToSave');
      
      print('🔧 SessionTypeRemoteDataSource: Calling FirestoreCollections.sessionTypes.add');
      final docRef = await FirestoreCollections.sessionTypes.add(dataToSave);
      print('🔧 SessionTypeRemoteDataSource: Firestore add completed, doc ID: ${docRef.id}');
      
      final createdSessionType = sessionType.copyWith(id: docRef.id);
      print('🔧 SessionTypeRemoteDataSource: Created session type model with ID');
      
      return createdSessionType;
    } catch (e, stackTrace) {
      print('❌ SessionTypeRemoteDataSource: Error creating session type: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<SessionTypeModel> updateSessionType(SessionTypeModel sessionType) async {
    if (sessionType.id == null) {
      throw Exception('Session type ID is required for update');
    }
    
    final dataToUpdate = sessionType.toMap();
    AppLogger.info('Updating session type ${sessionType.id} with data: $dataToUpdate');
    
    await FirestoreCollections.sessionType(sessionType.id!).update(dataToUpdate);
    AppLogger.info('Session type updated successfully');
    
    return sessionType;
  }

  @override
  Future<void> deleteSessionType(String id) async {
    try {
      // Try new collection first
      await FirestoreCollections.sessionType(id).delete();
    } catch (e) {
      try {
        // Try old collection if new one fails
        await _firestore.collection('sessionizer').doc('sessionTypes').collection('sessionTypes').doc(id).delete();
      } catch (e2) {
        throw Exception('Session type not found in either collection');
      }
    }
  }
}
