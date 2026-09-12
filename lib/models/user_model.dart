import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final List<String>? following;
  final List<String>? followers;
  final Map<String, dynamic>? settings;
  final String? fcmToken;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.following,
    this.followers,
    this.settings,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isVerified': isVerified,
      'following': following,
      'followers': followers,
      'settings': settings,
      'fcmToken': fcmToken,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isVerified: map['isVerified'] ?? false,
      following: List<String>.from(map['following'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      fcmToken: map['fcmToken'],
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    List<String>? following,
    List<String>? followers,
    Map<String, dynamic>? settings,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      settings: settings ?? this.settings,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
