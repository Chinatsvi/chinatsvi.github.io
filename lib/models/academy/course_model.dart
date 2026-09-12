import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String title;
  final String shortDescription;
  final String description;
  final String categoryId;
  final String categoryName;
  final String difficulty; // Beginner, Intermediate, Advanced
  final String language;
  final String? thumbnailUrl;
  final String instructorName;
  final String estimatedDuration;
  final bool isFree;
  final bool isFeatured;
  final String status; // 'draft', 'review', 'published', 'archived'
  final List<String> targetRegions;
  final List<String> targetCountries;
  final String? cropOrLivestock;
  final List<String> whatYouWillLearn;
  final String? agriculturalSource;
  final String? disclaimer;
  final String version;
  final DateTime? lastReviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final int lessonCount;
  final int enrolledCount;
  final int completionCount;
  final double rating;

  CourseModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.difficulty = 'Beginner',
    this.language = 'English',
    this.thumbnailUrl,
    this.instructorName = 'AgriBase Agronomist',
    this.estimatedDuration = '1h 30m',
    this.isFree = true,
    this.isFeatured = false,
    this.status = 'published',
    this.targetRegions = const [],
    this.targetCountries = const [],
    this.cropOrLivestock,
    this.whatYouWillLearn = const [],
    this.agriculturalSource,
    this.disclaimer,
    this.version = '1.0',
    this.lastReviewedAt,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.lessonCount = 0,
    this.enrolledCount = 0,
    this.completionCount = 0,
    this.rating = 5.0,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CourseModel.fromMap(data, doc.id);
  }

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return CourseModel(
      id: id,
      title: map['title']?.toString() ?? 'Untitled Course',
      shortDescription: map['shortDescription']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? 'crop_production',
      categoryName: map['categoryName']?.toString() ?? 'Crop Production',
      difficulty: map['difficulty']?.toString() ?? 'Beginner',
      language: map['language']?.toString() ?? 'English',
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      instructorName: map['instructorName']?.toString() ?? 'AgriBase Agronomist',
      estimatedDuration: map['estimatedDuration']?.toString() ?? '1h 30m',
      isFree: map['isFree'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      status: map['status']?.toString() ?? 'published',
      targetRegions: parseStringList(map['targetRegions']),
      targetCountries: parseStringList(map['targetCountries']),
      cropOrLivestock: map['cropOrLivestock']?.toString(),
      whatYouWillLearn: parseStringList(map['whatYouWillLearn']),
      agriculturalSource: map['agriculturalSource']?.toString(),
      disclaimer: map['disclaimer']?.toString(),
      version: map['version']?.toString() ?? '1.0',
      lastReviewedAt: parseDate(map['lastReviewedAt']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      publishedAt: parseDate(map['publishedAt']),
      lessonCount: (map['lessonCount'] as num?)?.toInt() ?? 0,
      enrolledCount: (map['enrolledCount'] as num?)?.toInt() ?? 0,
      completionCount: (map['completionCount'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'shortDescription': shortDescription,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'difficulty': difficulty,
      'language': language,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'instructorName': instructorName,
      'estimatedDuration': estimatedDuration,
      'isFree': isFree,
      'isFeatured': isFeatured,
      'status': status,
      'targetRegions': targetRegions,
      'targetCountries': targetCountries,
      if (cropOrLivestock != null) 'cropOrLivestock': cropOrLivestock,
      'whatYouWillLearn': whatYouWillLearn,
      if (agriculturalSource != null) 'agriculturalSource': agriculturalSource,
      if (disclaimer != null) 'disclaimer': disclaimer,
      'version': version,
      if (lastReviewedAt != null) 'lastReviewedAt': lastReviewedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (publishedAt != null) 'publishedAt': publishedAt,
      'lessonCount': lessonCount,
      'enrolledCount': enrolledCount,
      'completionCount': completionCount,
      'rating': rating,
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? shortDescription,
    String? description,
    String? categoryId,
    String? categoryName,
    String? difficulty,
    String? language,
    String? thumbnailUrl,
    String? instructorName,
    String? estimatedDuration,
    bool? isFree,
    bool? isFeatured,
    String? status,
    List<String>? targetRegions,
    List<String>? targetCountries,
    String? cropOrLivestock,
    List<String>? whatYouWillLearn,
    String? agriculturalSource,
    String? disclaimer,
    String? version,
    DateTime? lastReviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    int? lessonCount,
    int? enrolledCount,
    int? completionCount,
    double? rating,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructorName: instructorName ?? this.instructorName,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isFree: isFree ?? this.isFree,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
      targetRegions: targetRegions ?? this.targetRegions,
      targetCountries: targetCountries ?? this.targetCountries,
      cropOrLivestock: cropOrLivestock ?? this.cropOrLivestock,
      whatYouWillLearn: whatYouWillLearn ?? this.whatYouWillLearn,
      agriculturalSource: agriculturalSource ?? this.agriculturalSource,
      disclaimer: disclaimer ?? this.disclaimer,
      version: version ?? this.version,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      lessonCount: lessonCount ?? this.lessonCount,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      completionCount: completionCount ?? this.completionCount,
      rating: rating ?? this.rating,
    );
  }
}
