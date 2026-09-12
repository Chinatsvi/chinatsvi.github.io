import 'package:cloud_firestore/cloud_firestore.dart';

class AcademyBadgeModel {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String category;
  final DateTime earnedAt;

  AcademyBadgeModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.earnedAt,
  });

  factory AcademyBadgeModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AcademyBadgeModel(
      id: id,
      name: map['name']?.toString() ?? 'Learner',
      icon: map['icon']?.toString() ?? '🌱',
      description: map['description']?.toString() ?? 'Completed an agricultural course module',
      category: map['category']?.toString() ?? 'General',
      earnedAt: parseDate(map['earnedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
      'category': category,
      'earnedAt': earnedAt,
    };
  }
}

class AcademyBookmarkModel {
  final String id;
  final String type; // 'course' or 'lesson'
  final String courseId;
  final String? lessonId;
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;
  final DateTime createdAt;

  AcademyBookmarkModel({
    required this.id,
    required this.type,
    required this.courseId,
    this.lessonId,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory AcademyBookmarkModel.fromFirestore(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AcademyBookmarkModel(
      id: doc.id,
      type: map['type']?.toString() ?? 'course',
      courseId: map['courseId']?.toString() ?? '',
      lessonId: map['lessonId']?.toString(),
      title: map['title']?.toString() ?? 'Saved Item',
      subtitle: map['subtitle']?.toString(),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'courseId': courseId,
      if (lessonId != null) 'lessonId': lessonId,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt,
    };
  }
}
