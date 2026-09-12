import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

// 👇 Make sure you have run `flutterfire configure`
// and that firebase_options.dart exists in lib/
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await migrateFarmers();
}

/// One-time migration to fix legacy string fields in farmers collection
Future<void> migrateFarmers() async {
  final farmersRef = FirebaseFirestore.instance.collection('farmers');
  final snapshot = await farmersRef.get();

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final updates = <String, dynamic>{};

    // 🔹 Fix work field
    if (data['work'] is String) {
      final workString = data['work'] as String;
      updates['work'] = [
        {
          'role': workString,
          'company': '',
          'description': '',
          'startDate': '',
          'endDate': '',
        },
      ];
    }

    // 🔹 Fix education field
    if (data['education'] is String) {
      final eduString = data['education'] as String;
      updates['education'] = [
        {
          'degree': eduString,
          'institution': '',
          'certificate': '',
          'startDate': '',
          'endDate': '',
        },
      ];
    }

    // 🔹 Fix list fields that may have been stored as strings
    for (var field in [
      'crops',
      'followers',
      'following',
      'products',
      'socialLinks',
    ]) {
      if (data[field] is String) {
        updates[field] = [data[field]];
      }
    }

    if (updates.isNotEmpty) {
      developer.log(
        "Updating farmer ${doc.id} with $updates",
        name: 'migrateFarmers',
      );
      await doc.reference.update(updates);
    }
  }

  developer.log("Migration complete ✅", name: 'migrateFarmers');
}
