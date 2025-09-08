import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/bookable_session/data/models/bookable_session_model.dart';
import 'package:myapp/core/config/firestore_collections.dart';

abstract class BookableSessionRemoteDataSource {
  Stream<List<BookableSessionModel>> getBookableSessions(String instructorId);
  Stream<List<BookableSessionModel>> getAllBookableSessions();
  Future<BookableSessionModel> getBookableSession(String id);
  Future<BookableSessionModel> createBookableSession(BookableSessionModel bookableSession);
  Future<BookableSessionModel> updateBookableSession(BookableSessionModel bookableSession);
  Future<void> deleteBookableSession(String id);
}

class BookableSessionRemoteDataSourceImpl implements BookableSessionRemoteDataSource {
  final FirebaseFirestore _firestore;

  BookableSessionRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<BookableSessionModel>> getBookableSessions(String instructorId) {
    print('DEBUG: Querying bookable_sessions for instructorId: $instructorId');
    
    return FirestoreQueries.getBookableSessionsByInstructor(instructorId)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Found ${snapshot.docs.length} sessions for instructor $instructorId');
          print('DEBUG: Querying collection: sessionizer/bookable_sessions/bookable_sessions');
          print('DEBUG: Instructor ID filter: $instructorId');
          if (snapshot.docs.isEmpty) {
            print('DEBUG: No documents found in bookable_sessions collection');
          }
          final sessions = snapshot.docs
              .map((doc) {
                final data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
                print('DEBUG: Raw session data: $data');
                return BookableSessionModel.fromMap(data);
              })
              .toList();
          for (final session in sessions) {
            print('DEBUG: Session ${session.id} - instructorId: ${session.instructorId}, sessionTypeIds: ${session.sessionTypeIds}');
          }
          return sessions;
        })
        .handleError((error) {
          print('❌ ERROR in getBookableSessions: $error');
          print('❌ Error type: ${error.runtimeType}');
          if (error.toString().contains('permission-denied')) {
            print('❌ PERMISSION DENIED - Check Firestore rules for play database');
          }
          throw error;
        });
  }

  @override
  Stream<List<BookableSessionModel>> getAllBookableSessions() {
    return FirestoreCollections.bookableSessions
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => BookableSessionModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList();
          return sessions;
        });
  }

  @override
  Future<BookableSessionModel> getBookableSession(String id) async {
    final doc = await FirestoreCollections.bookableSession(id).get();
    if (!doc.exists) {
      throw Exception('Bookable session not found');
    }
    return BookableSessionModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  @override
  Future<BookableSessionModel> createBookableSession(BookableSessionModel bookableSession) async {
    final docRef = await FirestoreCollections.bookableSessions.add(bookableSession.toMap());
    final createdSession = bookableSession.copyWith(id: docRef.id);
    await docRef.set(createdSession.toMap());
    return createdSession;
  }

  @override
  Future<BookableSessionModel> updateBookableSession(BookableSessionModel bookableSession) async {
    if (bookableSession.id == null) {
      throw Exception('Bookable session ID is required for update');
    }
    await FirestoreCollections.bookableSession(bookableSession.id!).update(bookableSession.toMap());
    return bookableSession;
  }

  @override
  Future<void> deleteBookableSession(String id) async {
    await FirestoreCollections.bookableSession(id).delete();
  }
}
