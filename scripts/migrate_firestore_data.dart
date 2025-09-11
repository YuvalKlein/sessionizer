import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to migrate Firestore data from old structure to new environment-based structure
/// 
/// Old structure: sessionizer/{collection}/{documents}
/// New structure: sessionizer/DevData/{collection}/{documents} and sessionizer/ProdData/{collection}/{documents}
/// 
/// Usage:
/// dart run scripts/migrate_firestore_data.dart
void main() async {
  print('🔄 Starting Firestore data migration...');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  
  // Collections to migrate
  final collections = [
    'users',
    'locations', 
    'bookable_sessions',
    'bookings',
    'schedules',
    'session_types',
    'notifications',
    'scheduled_notifications',
    'mail'
  ];
  
  try {
    // Migrate to DevData
    print('📦 Migrating data to DevData...');
    await migrateCollection(firestore, collections, 'DevData');
    
    // Migrate to ProdData (copy of DevData for now)
    print('📦 Migrating data to ProdData...');
    await migrateCollection(firestore, collections, 'ProdData');
    
    print('✅ Migration completed successfully!');
    print('📊 Data is now available in both DevData and ProdData collections');
    
  } catch (e) {
    print('❌ Migration failed: $e');
    exit(1);
  }
}

/// Migrate a collection from old structure to new environment structure
Future<void> migrateCollection(
  FirebaseFirestore firestore, 
  List<String> collections, 
  String environmentPrefix
) async {
  for (final collectionName in collections) {
    print('  📁 Migrating $collectionName to $environmentPrefix...');
    
    try {
      // Get documents from old structure
      final oldCollection = firestore
          .collection('sessionizer')
          .doc(collectionName)
          .collection(collectionName);
      
      final snapshot = await oldCollection.get();
      
      if (snapshot.docs.isEmpty) {
        print('    ⚠️ No documents found in $collectionName');
        continue;
      }
      
      // Create new collection reference
      final newCollection = firestore
          .collection('sessionizer')
          .doc(environmentPrefix)
          .collection(collectionName);
      
      // Migrate each document
      final batch = firestore.batch();
      int migratedCount = 0;
      
      for (final doc in snapshot.docs) {
        final newDocRef = newCollection.doc(doc.id);
        batch.set(newDocRef, doc.data());
        migratedCount++;
      }
      
      // Commit the batch
      await batch.commit();
      print('    ✅ Migrated $migratedCount documents to $environmentPrefix/$collectionName');
      
    } catch (e) {
      print('    ❌ Failed to migrate $collectionName: $e');
    }
  }
}
