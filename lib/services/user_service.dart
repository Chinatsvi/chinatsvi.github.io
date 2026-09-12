import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePic;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePic,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserModel(
      uid: doc.id,
      name: data?['user_name'] ?? '',
      email: data?['email'] ?? '',
      profilePic: data?['profile_pic'],
      updatedAt: data?['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_name': name,
      'email': email,
      'profile_pic': profilePic,
      'updated_at': updatedAt,
    };
  }
}

class UserCache {
  static final Map<String, UserModel> _cache = {};

  static void update(UserModel user) {
    _cache[user.uid] = user;
    debugPrint('🗂️ UserCache updated: ${user.uid} → ${user.name}');
  }

  static UserModel? get(String uid) {
    return _cache[uid];
  }

  static void clear() {
    _cache.clear();
    debugPrint('🗑️ UserCache cleared');
  }

  static void remove(String uid) {
    _cache.remove(uid);
  }

  static List<UserModel> getAll() {
    return _cache.values.toList();
  }
}

class UserService {
  /// STEP 1: Update the name in Firestore (farmers collection)
  static Future<void> updateUserName(String uid, String newName) async {
    try {
      debugPrint('🔄 Updating user name: $uid → "$newName"');
      
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .update({
        'user_name': newName,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ User name updated successfully!');
      
    } catch (e) {
      debugPrint('❌ Error updating user name: $e');
      rethrow;
    }
  }

  /// STEP 2: Listen to user changes (REAL-TIME)
  static Stream<UserModel> userStream(String uid) {
    debugPrint('👂 Starting user stream for: $uid');
    
    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .snapshots()
        .map((doc) {
          final user = UserModel.fromFirestore(doc);
          UserCache.update(user); // Update cache automatically
          return user;
        });
  }

  /// Get user once (with cache fallback)
  static Future<UserModel?> getUser(String uid) async {
    // Check cache first
    final cachedUser = UserCache.get(uid);
    if (cachedUser != null) {
      debugPrint('🗂️ Using cached user: $uid');
      return cachedUser;
    }

    // Fetch from Firestore
    try {
      debugPrint('📥 Fetching user from Firestore: $uid');
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        UserCache.update(user);
        return user;
      }
    } catch (e) {
      debugPrint('❌ Error fetching user: $e');
    }
    
    return null;
  }

  /// Batch fetch multiple users
  static Future<Map<String, UserModel>> getUsers(List<String> uids) async {
    final result = <String, UserModel>{};
    
    for (final uid in uids) {
      final user = await getUser(uid);
      if (user != null) {
        result[uid] = user;
      }
    }
    
    debugPrint('📥 Batch fetched ${result.length} users');
    return result;
  }

  /// Update user profile (name + avatar)
  static Future<void> updateUserProfile({
    required String uid,
    required String name,
    String? profilePic,
  }) async {
    try {
      debugPrint('🔄 Updating user profile: $uid');
      
      final updateData = <String, dynamic>{
        'user_name': name,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (profilePic != null) {
        updateData['profile_pic'] = profilePic;
      }
      
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .update(updateData);
      
      debugPrint('✅ User profile updated successfully!');
      
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    }
  }
}
