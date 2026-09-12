import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_block_model.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int order;
  final String duration;
  final bool isRequired;
  final bool isPreview;
  final String status; // 'draft', 'published'
  final List<LessonBlockModel> blocks;
  final List<String> sourcesAndReferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description = '',
    this.order = 0,
    this.duration = '10 min',
    this.isRequired = true,
    this.isPreview = false,
    this.status = 'published',
    this.blocks = const [],
    this.sourcesAndReferences = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc, String courseId) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return LessonModel.fromMap(data, doc.id, courseId);
  }

  factory LessonModel.fromMap(Map<String, dynamic> map, String id, String courseId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<LessonBlockModel> parseBlocks(dynamic val) {
      if (val is List) {
        return val.map((e) {
          if (e is Map<String, dynamic>) {
            return LessonBlockModel.fromMap(e);
          }
          return LessonBlockModel(id: '', type: LessonBlockType.text);
        }).toList();
      }
      return [];
    }

    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return LessonModel(
      id: id,
      courseId: courseId,
      title: map['title']?.toString() ?? 'Untitled Lesson',
      description: map['description']?.toString() ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      duration: map['duration']?.toString() ?? '10 min',
      isRequired: map['isRequired'] ?? true,
      isPreview: map['isPreview'] ?? false,
      status: map['status']?.toString() ?? 'published',
      blocks: parseBlocks(map['blocks']),
      sourcesAndReferences: parseStringList(map['sourcesAndReferences']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'order': order,
      'duration': duration,
      'isRequired': isRequired,
      'isPreview': isPreview,
      'status': status,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'sourcesAndReferences': sourcesAndReferences,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  LessonModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    int? order,
    String? duration,
    bool? isRequired,
    bool? isPreview,
    String? status,
    List<LessonBlockModel>? blocks,
    List<String>? sourcesAndReferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      duration: duration ?? this.duration,
      isRequired: isRequired ?? this.isRequired,
      isPreview: isPreview ?? this.isPreview,
      status: status ?? this.status,
      blocks: blocks ?? this.blocks,
      sourcesAndReferences: sourcesAndReferences ?? this.sourcesAndReferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
