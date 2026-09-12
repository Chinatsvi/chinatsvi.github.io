import 'package:cloud_firestore/cloud_firestore.dart';

/// Season Activity Model - Land prep, planting, weeding, fertilizing, harvesting
class SeasonActivity {
  final String id;
  final String farmerId;
  final String cropPlanId;
  final String activityType; // 'land_preparation', 'planting', 'weeding', 'fertilizing', 'pest_control', 'irrigation', 'harvesting', 'other'
  final String description;
  final DateTime plannedDate;
  final DateTime? completedDate;
  final String? status; // 'planned', 'in_progress', 'completed', 'delayed'
  final double? cost;
  final double? laborHours;
  final List<String>? inputsUsed; // Reference to inventory items used
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SeasonActivity({
    required this.id,
    required this.farmerId,
    required this.cropPlanId,
    required this.activityType,
    required this.description,
    required this.plannedDate,
    this.completedDate,
    this.status,
    this.cost,
    this.laborHours,
    this.inputsUsed,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory SeasonActivity.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeasonActivity(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      cropPlanId: data['cropPlanId'] ?? '',
      activityType: data['activityType'] ?? 'other',
      description: data['description'] ?? '',
      plannedDate: (data['plannedDate'] as Timestamp).toDate(),
      completedDate: data['completedDate'] != null
          ? (data['completedDate'] as Timestamp).toDate()
          : null,
      status: data['status'],
      cost: data['cost']?.toDouble(),
      laborHours: data['laborHours']?.toDouble(),
      inputsUsed: data['inputsUsed'] != null
          ? List<String>.from(data['inputsUsed'])
          : null,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'cropPlanId': cropPlanId,
      'activityType': activityType,
      'description': description,
      'plannedDate': Timestamp.fromDate(plannedDate),
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'status': status,
      'cost': cost,
      'laborHours': laborHours,
      'inputsUsed': inputsUsed,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isCompleted => status == 'completed' || completedDate != null;

  String get activityTypeDisplay {
    final Map<String, String> displayNames = {
      'land_preparation': 'Land Preparation',
      'planting': 'Planting',
      'weeding': 'Weeding',
      'fertilizing': 'Fertilizing',
      'pest_control': 'Pest Control',
      'irrigation': 'Irrigation',
      'harvesting': 'Harvesting',
      'other': 'Other Activity',
    };
    return displayNames[activityType] ?? 'Activity';
  }

  SeasonActivity copyWith({
    String? id,
    String? farmerId,
    String? cropPlanId,
    String? activityType,
    String? description,
    DateTime? plannedDate,
    DateTime? completedDate,
    String? status,
    double? cost,
    double? laborHours,
    List<String>? inputsUsed,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SeasonActivity(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropPlanId: cropPlanId ?? this.cropPlanId,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      plannedDate: plannedDate ?? this.plannedDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      laborHours: laborHours ?? this.laborHours,
      inputsUsed: inputsUsed ?? this.inputsUsed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
