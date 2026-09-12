import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/utils/formatters.dart';

class WorkExperience {
  final String? role;
  final String? company;
  final String? description;
  final String? startDate;
  final String? endDate;

  WorkExperience({
    this.role,
    this.company,
    this.description,
    this.startDate,
    this.endDate,
  });

  factory WorkExperience.fromMap(Map<String, dynamic> map) {
    return WorkExperience(
      role: map['role']?.toString(),
      company: map['company']?.toString(),
      description: map['description']?.toString(),
      startDate: map['startDate']?.toString(),
      endDate: map['endDate']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (role != null) 'role': role,
      if (company != null) 'company': company,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
  }
}

class EducationEntry {
  final String? degree;
  final String? institution;
  final String? startDate;
  final String? endDate;
  final String? certificate;
  final String? description;

  EducationEntry({
    this.degree,
    this.institution,
    this.startDate,
    this.endDate,
    this.certificate,
    this.description,
  });

  factory EducationEntry.fromMap(Map<String, dynamic> map) {
    return EducationEntry(
      degree: map['degree']?.toString(),
      institution: map['institution']?.toString(),
      startDate: map['startDate']?.toString(),
      endDate: map['endDate']?.toString(),
      certificate: map['certificate']?.toString(),
      description: map['description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (degree != null) 'degree': degree,
      if (institution != null) 'institution': institution,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (certificate != null) 'certificate': certificate,
      if (description != null) 'description': description,
    };
  }
}

class CameraEntry {
  final String id;
  final String name;
  final String streamUrl;
  final String? thumbnailUrl;
  final bool isActive;
  final DateTime? lastActive;

  CameraEntry({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.thumbnailUrl,
    this.isActive = true,
    this.lastActive,
  });

  factory CameraEntry.fromMap(Map<String, dynamic> map) {
    return CameraEntry(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed Camera',
      streamUrl: map['streamUrl']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      isActive: map['isActive'] ?? true,
      lastActive: map['lastActive']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'isActive': isActive,
      if (lastActive != null) 'lastActive': lastActive,
    };
  }
}

class RecordingEntry {
  final String id;
  final DateTime date;
  final String url;
  final Duration duration;
  final int fileSize; // in bytes

  RecordingEntry({
    required this.date,
    required this.url,
    this.id = '',
    Duration? duration,
    this.fileSize = 0,
  }) : duration = duration ?? Duration.zero;

  factory RecordingEntry.fromMap(Map<String, dynamic> map) {
    return RecordingEntry(
      id: map['id']?.toString() ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      url: map['url']?.toString() ?? '',
      duration: Duration(seconds: (map['duration'] ?? 0) as int),
      fileSize: (map['fileSize'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'url': url,
      'duration': duration.inSeconds,
      'fileSize': fileSize,
    };
  }
}

/// ✅ Farmer Profile Model (Name required, everything else optional)
class FarmerModel {
  final String id;
  final String name; // ✅ REQUIRED
  final String? bio;
  final String? location;

  final List<WorkExperience> workList;
  final List<EducationEntry> educationList;

  // Legacy fields for backward compatibility
  final String? workLegacy;
  final String? experienceLegacy;
  final String? educationLegacy;
  final String? college;
  final String? university;
  final String? highSchool;

  String? get work => workList.isNotEmpty ? workList.first.role : null;
  String? get education =>
      educationList.isNotEmpty ? educationList.first.degree : null;

  final List<String> crops;
  final List<String> followers;
  final List<String> following;
  final int posts;

  final String? profilePic;
  final String? coverPhoto;

  final bool isSeller;
  final List<String> products;
  final double rating;
  final int totalSales;
  final String? phone;
  final String? whatsapp;

  final String? accountType;
  final String? email;
  final String? farmType;
  final String? website;
  final List<String> socialLinks;
  final String? cooperative;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<CameraEntry> cameras;
  final List<RecordingEntry> recordings;

  // ✅ Verification fields
  final bool isVerified; // Green tick display
  final String
  verificationStatus; // "none", "pending", "approved", "rejected", "expired"
  final bool verificationPaid; // Subscription/payment flag
  final DateTime? verificationPaidAt; // ✅ Track last payment date

  FarmerModel({
    required this.id,
    required this.name,
    this.bio,
    this.location,
    this.workList = const [],
    this.educationList = const [],
    this.workLegacy,
    this.experienceLegacy,
    this.educationLegacy,
    this.college,
    this.university,
    this.highSchool,
    this.crops = const [],
    this.followers = const [],
    this.following = const [],
    this.posts = 0,
    this.profilePic,
    this.coverPhoto,
    this.isSeller = false,
    this.products = const [],
    this.rating = 0.0,
    this.totalSales = 0,
    this.phone,
    this.whatsapp,
    this.accountType,
    this.email,
    this.farmType,
    this.website,
    this.socialLinks = const [],
    this.cooperative,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.cameras = const [],
    this.recordings = const [],
    this.isVerified = false,
    this.verificationStatus = "none",
    this.verificationPaid = false,
    this.verificationPaidAt,
  });

  /// ✅ SAFE, OPTIONAL, NON‑MANDATORY fromMap()
  factory FarmerModel.fromMap(Map<String, dynamic> map, String id) {
    List safeList(dynamic value) => value is List ? value : [];
    Map<String, dynamic> safeMap(dynamic value) =>
        value is Map<String, dynamic> ? value : {};
    double safeDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime? safeDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final String safeName = (map['user_name'] ?? map['name'] ?? '')
        .toString()
        .trim();

    return FarmerModel(
      id: id,
      name: safeName.isNotEmpty ? safeName : "Unnamed Farmer",
      bio: map['bio']?.toString(),
      location: _formatLocationFromMap(map['location']),
      // Handle both new list-based structure and legacy flat fields
      workList:
          (map['workList'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromMap(e as Map<String, dynamic>))
              .toList() ??
          (map['work'] != null && map['work'] is! List
              ? [
                  WorkExperience.fromMap({'role': map['work'].toString()}),
                ]
              : safeList(
                  map['work'],
                ).map((w) => WorkExperience.fromMap(safeMap(w))).toList()),
      educationList:
          (map['educationList'] as List<dynamic>?)
              ?.map((e) => EducationEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          (map['education'] != null && map['education'] is! List
              ? [
                  EducationEntry.fromMap({
                    'degree': map['education'].toString(),
                  }),
                ]
              : safeList(
                  map['education'],
                ).map((e) => EducationEntry.fromMap(safeMap(e))).toList()),
      crops: safeList(map['crops']).map((e) => e.toString()).toList(),
      followers: safeList(map['followers']).map((e) => e.toString()).toList(),
      following: safeList(map['following']).map((e) => e.toString()).toList(),
      posts: (map['posts'] ?? map['postCount'] ?? map['postsCount']) is int
          ? (map['posts'] ?? map['postCount'] ?? map['postsCount']) as int
          : int.tryParse((map['posts'] ?? map['postCount'] ?? map['postsCount'])?.toString() ?? '0') ?? 0,
      profilePic: map['profile_pic']?.toString(),
      coverPhoto: map['cover_photo']?.toString(),
      isSeller: map['isSeller'] ?? false,
      products: safeList(map['products']).map((e) => e.toString()).toList(),
      rating: safeDouble(map['rating']),
      totalSales: map['totalSales'] ?? 0,
      phone: map['phone']?.toString(),
      whatsapp: map['whatsapp']?.toString(),
      accountType: map['accountType']?.toString(),
      email: map['email']?.toString(),
      farmType: map['farmType']?.toString(),
      website: map['website']?.toString(),
      socialLinks: safeList(
        map['socialLinks'],
      ).map((e) => e.toString()).toList(),
      cooperative: map['cooperative']?.toString(),
      status: map['status']?.toString(),
      createdAt: safeDate(map['created_at']),
      updatedAt: safeDate(map['updated_at']),
      cameras: safeList(
        map['cameras'],
      ).map((c) => CameraEntry.fromMap(safeMap(c))).toList(),
      recordings: safeList(
        map['recordings'],
      ).map((r) => RecordingEntry.fromMap(safeMap(r))).toList(),
      isVerified: map['isVerified'] ?? false,
      verificationStatus: map['verificationStatus']?.toString() ?? "none",
      verificationPaid: map['verificationPaid'] ?? false,
      verificationPaidAt:
          safeDate(map['verificationPaidAt']) ??
          safeDate(map['verificationPaidat']),
    );
  }

  factory FarmerModel.fromDocument(DocumentSnapshot doc) {
    return FarmerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_name': name,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      // Handle both new list-based structure and legacy flat fields
      if (workList.isNotEmpty)
        'workList': workList.map((e) => e.toMap()).toList(),
      if (workLegacy != null) 'work': workLegacy,
      if (experienceLegacy != null) 'experience': experienceLegacy,
      if (educationList.isNotEmpty)
        'educationList': educationList.map((e) => e.toMap()).toList(),
      if (educationLegacy != null) 'education': educationLegacy,
      if (college != null) 'college': college,
      if (university != null) 'university': university,
      if (highSchool != null) 'highSchool': highSchool,
      if (crops.isNotEmpty) 'crops': crops,
      if (followers.isNotEmpty) 'followers': followers,
      if (following.isNotEmpty) 'following': following,
      'posts': posts,
      if (profilePic != null) 'profile_pic': profilePic,
      if (coverPhoto != null) 'cover_photo': coverPhoto,
      'isSeller': isSeller,
      if (products.isNotEmpty) 'products': products,
      'rating': rating,
      'totalSales': totalSales,
      if (phone != null) 'phone': phone,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (accountType != null) 'accountType': accountType,
      if (email != null) 'email': email,
      if (farmType != null) 'farmType': farmType,
      if (website != null) 'website': website,
      if (socialLinks.isNotEmpty) 'socialLinks': socialLinks,
      if (cooperative != null) 'cooperative': cooperative,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cameras.isNotEmpty) 'cameras': cameras.map((c) => c.toMap()).toList(),
      if (recordings.isNotEmpty)
        'recordings': recordings.map((r) => r.toMap()).toList(),
      // ✅ Verification fields
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationPaid': verificationPaid,
      if (verificationPaidAt != null) 'verificationPaidAt': verificationPaidAt,
    };
  }

  /// ✅ Helper: should show tick
  bool get showTick {
    return isVerified &&
        verificationStatus == "approved" &&
        verificationPaid &&
        !isPaymentExpired;
  }

  /// Helper: check if payment expired
  bool get isPaymentExpired {
    if (verificationPaidAt == null) return true;
    final now = DateTime.now();
    return now.difference(verificationPaidAt!).inDays >=
        30; // Changed to 30 days for consistency
  }

  /// Public helper method to format location data properly
  static String formatLocation(dynamic location) {
    return Formatter.formatLocation(location);
  }

  /// Internal helper to handle both string and map location values
  static String? _formatLocationFromMap(dynamic location) {
    final formatted = Formatter.formatLocation(location);
    return formatted.isNotEmpty ? formatted : null;
  }
}

