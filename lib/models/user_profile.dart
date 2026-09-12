import 'package:agribased/app/utils/formatters.dart';

/// User profile model for farmers in AgriBase
class UserProfile {
  final String id;
  final String userName;              // ✅ standardized field
  final String? email;
  final String? profilePic;           // ✅ standardized field
  final String? coverPhoto;           // ✅ added for consistency
  final String? location;
  final String? bio;
  final double rating;
  final int reviewsCount;
  final String? badgeLevel;
  final List<String> crops;           // ✅ default to empty list
  final bool? isPrivate;
  final bool? hideFollowing;
  final List<String> followers;       // ✅ default to empty list
  final List<String> following;       // ✅ added for parity
  final bool? isDeactivated;

  UserProfile({
    required this.id,
    required this.userName,
    this.email,
    this.profilePic,
    this.coverPhoto,
    this.location,
    this.bio,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.badgeLevel,
    List<String>? crops,
    this.isPrivate,
    this.hideFollowing,
    List<String>? followers,
    List<String>? following,
    this.isDeactivated,
  })  : crops = crops ?? [],
        followers = followers ?? [],
        following = following ?? [];

  /// Factory for parsing JSON (Firestore)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      userName: json['user_name'] ?? '',          // ✅ consistent
      email: json['email'],
      profilePic: json['profile_pic'],
      coverPhoto: json['cover_photo'],
      location: json['location'] != null
          ? Formatter.formatLocation(json['location'])
          : null,
      bio: json['bio'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      badgeLevel: json['badgeLevel'],
      crops: List<String>.from(json['crops'] ?? []),
      isPrivate: json['isPrivate'],
      hideFollowing: json['hideFollowing'],
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      isDeactivated: json['isDeactivated'],
    );
  }

  /// Convert to JSON (Firestore compatible)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,          // ✅ consistent
      'email': email,
      'profile_pic': profilePic,
      'cover_photo': coverPhoto,
      'location': location,
      'bio': bio,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'badgeLevel': badgeLevel,
      'crops': crops,
      'isPrivate': isPrivate,
      'hideFollowing': hideFollowing,
      'followers': followers,
      'following': following,
      'isDeactivated': isDeactivated,
    };
  }

  /// CopyWith for immutability and easy updates
  UserProfile copyWith({
    String? id,
    String? userName,
    String? email,
    String? profilePic,
    String? coverPhoto,
    String? location,
    String? bio,
    double? rating,
    int? reviewsCount,
    String? badgeLevel,
    List<String>? crops,
    bool? isPrivate,
    bool? hideFollowing,
    List<String>? followers,
    List<String>? following,
    bool? isDeactivated,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      badgeLevel: badgeLevel ?? this.badgeLevel,
      crops: crops ?? this.crops,
      isPrivate: isPrivate ?? this.isPrivate,
      hideFollowing: hideFollowing ?? this.hideFollowing,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isDeactivated: isDeactivated ?? this.isDeactivated,
    );
  }
}