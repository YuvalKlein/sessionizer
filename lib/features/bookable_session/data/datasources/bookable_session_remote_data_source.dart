import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/bookable_session/data/models/bookable_session_model.dart';

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
    
    return _firestore
        .collection('sessionizer/bookable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Found ${snapshot.docs.length} sessions for instructor $instructorId');
          print('DEBUG: Querying collection: bookable_sessions');
          print('DEBUG: Instructor ID filter: $instructorId');
          if (snapshot.docs.isEmpty) {
            print('DEBUG: No documents found in bookable_sessions collection');
          }
          final sessions = snapshot.docs
              .map((doc) {
                final data = {...doc.data(), 'id': doc.id};
                print('DEBUG: Raw session data: $data');
                return BookableSessionModel.fromMap(data);
              })
              .toList();
          for (final session in sessions) {
            print('DEBUG: Session ${session.id} - instructorId: ${session.instructorId}, sessionTypeIds: ${session.sessionTypeIds}');
          }
          return sessions;
        });
  }

  @override
  Stream<List<BookableSessionModel>> getAllBookableSessions() {
    return _firestore
        .collection('sessionizer/bookable_sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => BookableSessionModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          return sessions;
        });
  }

  @override
  Future<BookableSessionModel> getBookableSession(String id) async {
    final doc = await _firestore.collection('bookable_sessions').doc(id).get();
    if (!doc.exists) {
      throw Exception('Bookable session not found');
    }
    return BookableSessionModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<BookableSessionModel> createBookableSession(BookableSessionModel bookableSession) async {
    final docRef = await _firestore.collection('bookable_sessions').add(bookableSession.toMap());
    final createdSession = bookableSession.copyWith(id: docRef.id);
    await docRef.set(createdSession.toMap());
    return createdSession;
  }

  @override
  Future<BookableSessionModel> updateBookableSession(BookableSessionModel bookableSession) async {
    await _firestore
        .collection('sessionizer/bookable_sessions')
        .doc(bookableSession.id)
        .update(bookableSession.toMap());
    return bookableSession;
  }

  @override
  Future<void> deleteBookableSession(String id) async {
    await _firestore.collection('bookable_sessions').doc(id).delete();
  }
}
