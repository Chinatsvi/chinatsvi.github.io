import 'package:cloud_firestore/cloud_firestore.dart';

class CourseProgressModel {
  final String courseId;
  final String userId;
  final DateTime startedAt;
  final DateTime lastAccessedAt;
  final DateTime? completedAt;
  final double progressPercent; // 0.0 - 100.0
  final String? lastLessonId;
  final bool completed;
  final List<String> completedLessonIds;
  final Map<String, int> quizScores; // lessonId / quizId -> score (0-100)
  final int bestQuizScore;

  CourseProgressModel({
    required this.courseId,
    required this.userId,
    required this.startedAt,
    required this.lastAccessedAt,
    this.completedAt,
    this.progressPercent = 0.0,
    this.lastLessonId,
    this.completed = false,
    this.completedLessonIds = const [],
    this.quizScores = const {},
    this.bestQuizScore = 0,
  });

  factory CourseProgressModel.fromFirestore(DocumentSnapshot doc, String userId) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CourseProgressModel.fromMap(data, doc.id, userId);
  }

  factory CourseProgressModel.fromMap(
    Map<String, dynamic> map,
    String courseId,
    String userId,
  ) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
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

    Map<String, int> parseScores(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      }
      return {};
    }

    return CourseProgressModel(
      courseId: courseId,
      userId: userId,
      startedAt: parseDate(map['startedAt']),
      lastAccessedAt: parseDate(map['lastAccessedAt']),
      completedAt: parseOptionalDate(map['completedAt']),
      progressPercent: (map['progressPercent'] as num?)?.toDouble() ?? 0.0,
      lastLessonId: map['lastLessonId']?.toString(),
      completed: map['completed'] ?? false,
      completedLessonIds: parseStringList(map['completedLessonIds']),
      quizScores: parseScores(map['quizScores']),
      bestQuizScore: (map['bestQuizScore'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'userId': userId,
      'startedAt': startedAt,
      'lastAccessedAt': lastAccessedAt,
      if (completedAt != null) 'completedAt': completedAt,
      'progressPercent': progressPercent,
      if (lastLessonId != null) 'lastLessonId': lastLessonId,
      'completed': completed,
      'completedLessonIds': completedLessonIds,
      'quizScores': quizScores,
      'bestQuizScore': bestQuizScore,
    };
  }

  CourseProgressModel copyWith({
    String? courseId,
    String? userId,
    DateTime? startedAt,
    DateTime? lastAccessedAt,
    DateTime? completedAt,
    double? progressPercent,
    String? lastLessonId,
    bool? completed,
    List<String>? completedLessonIds,
    Map<String, int>? quizScores,
    int? bestQuizScore,
  }) {
    return CourseProgressModel(
      courseId: courseId ?? this.courseId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      completedAt: completedAt ?? this.completedAt,
      progressPercent: progressPercent ?? this.progressPercent,
      lastLessonId: lastLessonId ?? this.lastLessonId,
      completed: completed ?? this.completed,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      quizScores: quizScores ?? this.quizScores,
      bestQuizScore: bestQuizScore ?? this.bestQuizScore,
    );
  }
}
