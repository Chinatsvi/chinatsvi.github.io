import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonBlockType {
  text,
  image,
  video,
  pdf,
  tip,
  warning,
  quiz,
  calculator,
  link,
}

class LessonBlockModel {
  final String id;
  final LessonBlockType type;
  final int order;
  final String? content; // For text, tips, warnings, captions
  final String? title; // Block title / header
  final String? mediaUrl; // Image, Video, PDF URL
  final String? mediaReference;
  final String? thumbnailUrl;
  final String? caption;
  final String? calculatorType; // 'fertilizer', 'irrigation', 'profit', 'break_even', 'population', 'spacing'
  final String? linkUrl;
  final String? linkTitle;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LessonBlockModel({
    required this.id,
    required this.type,
    this.order = 0,
    this.content,
    this.title,
    this.mediaUrl,
    this.mediaReference,
    this.thumbnailUrl,
    this.caption,
    this.calculatorType,
    this.linkUrl,
    this.linkTitle,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory LessonBlockModel.fromMap(Map<String, dynamic> map, [String? blockId]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    LessonBlockType parseType(String? typeStr) {
      switch (typeStr?.toLowerCase()) {
        case 'image':
          return LessonBlockType.image;
        case 'video':
          return LessonBlockType.video;
        case 'pdf':
          return LessonBlockType.pdf;
        case 'tip':
        case 'farmer_tip':
          return LessonBlockType.tip;
        case 'warning':
          return LessonBlockType.warning;
        case 'quiz':
          return LessonBlockType.quiz;
        case 'calculator':
          return LessonBlockType.calculator;
        case 'link':
        case 'external_link':
          return LessonBlockType.link;
        case 'text':
        default:
          return LessonBlockType.text;
      }
    }

    return LessonBlockModel(
      id: blockId ?? map['id']?.toString() ?? '',
      type: parseType(map['type']?.toString()),
      order: (map['order'] as num?)?.toInt() ?? 0,
      content: map['content']?.toString(),
      title: map['title']?.toString(),
      mediaUrl: map['mediaUrl']?.toString(),
      mediaReference: map['mediaReference']?.toString(),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      caption: map['caption']?.toString(),
      calculatorType: map['calculatorType']?.toString(),
      linkUrl: map['linkUrl']?.toString(),
      linkTitle: map['linkTitle']?.toString(),
      metadata: map['metadata'] is Map<String, dynamic> ? map['metadata'] : null,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'order': order,
      if (content != null) 'content': content,
      if (title != null) 'title': title,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaReference != null) 'mediaReference': mediaReference,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (caption != null) 'caption': caption,
      if (calculatorType != null) 'calculatorType': calculatorType,
      if (linkUrl != null) 'linkUrl': linkUrl,
      if (linkTitle != null) 'linkTitle': linkTitle,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  LessonBlockModel copyWith({
    String? id,
    LessonBlockType? type,
    int? order,
    String? content,
    String? title,
    String? mediaUrl,
    String? mediaReference,
    String? thumbnailUrl,
    String? caption,
    String? calculatorType,
    String? linkUrl,
    String? linkTitle,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonBlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      order: order ?? this.order,
      content: content ?? this.content,
      title: title ?? this.title,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaReference: mediaReference ?? this.mediaReference,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      calculatorType: calculatorType ?? this.calculatorType,
      linkUrl: linkUrl ?? this.linkUrl,
      linkTitle: linkTitle ?? this.linkTitle,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
