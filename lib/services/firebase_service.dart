import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class FirebaseService {
  // Singleton
  FirebaseService._privateConstructor();
  static final FirebaseService instance = FirebaseService._privateConstructor();

  // Firebase instances (using the already initialized Firebase instance from main.dart)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Public getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseAuth get auth => _auth;
  FirebaseMessaging get messaging => _messaging;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseCrashlytics get crashlytics => _crashlytics;

  // Current user helpers
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool isCurrentUser(String userId) => _auth.currentUser?.uid == userId;

  // ---------------------
  // Firestore helpers
  // ---------------------
  DocumentReference farmerDoc(String userId) =>
      _firestore.collection('farmers').doc(userId); // ✅ consistent with rest of app

  CollectionReference postsCollection() =>
      _firestore.collection('posts');

  Future<void> setDocument(String path, Map<String, dynamic> data,
      {bool merge = true}) async {
    await _firestore.doc(path).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    await _firestore.doc(path).update(data);
  }

  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
  }

  Future<Map<String, dynamic>?> getDocument(String path) async {
    final doc = await _firestore.doc(path).get();
    return doc.exists ? doc.data() : null;
  }

  Stream<DocumentSnapshot> documentStream(String path) {
    return _firestore.doc(path).snapshots();
  }

  Stream<QuerySnapshot> collectionStream(String path) {
    return _firestore.collection(path).snapshots();
  }

  // ---------------------
  // Firebase Storage helpers
  // ---------------------
  Future<String> uploadFile(Reference ref, Uint8List data,
      {Map<String, String>? metadata}) async {
    final snapshot =
        await ref.putData(data, SettableMetadata(customMetadata: metadata));
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    await _storage.refFromURL(url).delete();
  }

  /// Chat media storage reference
  Reference chatMediaRef(String chatId, String fileName) {
    return _storage.ref().child('chat_media/$chatId/$fileName');
  }

  // ---------------------
  // Analytics & Crashlytics (safe usage)
  // ---------------------
  Future<void> logEvent(String name,
      {Map<String, Object?>? parameters}) async {
    final safeParams = parameters?.map(
      (key, value) => MapEntry(key, value ?? ''),
    );
    await _analytics.logEvent(name: name, parameters: safeParams);
  }

  Future<void> logError(String error, StackTrace? stackTrace) async {
    try {
      log('FirebaseService Error: $error',
          error: error, stackTrace: stackTrace);
      await _crashlytics.recordError(error, stackTrace ?? StackTrace.current);
    } catch (e) {
      log('Crashlytics logging failed', error: e);
    }
  }

  Future<void> setUserId(String? userId) async {
    if (userId != null) {
      try {
        await _analytics.setUserId(id: userId);
        await _crashlytics.setUserIdentifier(userId);
      } catch (e) {
        log('Error setting user ID', error: e);
      }
    }
  }
}