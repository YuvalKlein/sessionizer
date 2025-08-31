
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/session_template_model.dart';

class SessionTemplateService {
  final CollectionReference _sessionTemplateCollection = FirebaseFirestore.instance.collection('sessionTemplates');

  Stream<List<SessionTemplate>> getSessionTemplatesForInstructor(String instructorId) {
    return _sessionTemplateCollection
        .where('idInstructor', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SessionTemplate.fromFirestore(doc)).toList();
    });
  }
}
