class ActivityLogRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final String notes;
  final double? cost;
  final int? animalsAdded;
  final bool deleted;

  const ActivityLogRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.notes,
    this.cost,
    this.animalsAdded,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'date': date.toIso8601String(),
      'notes': notes,
      'cost': cost,
      'animalsAdded': animalsAdded,
      'deleted': deleted,
    };
  }

  factory ActivityLogRecord.fromMap(Map<String, dynamic> map) {
    return ActivityLogRecord(
      id: map['id'] as String,
      animalId: map['animalId'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String? ?? '',
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      animalsAdded: map['animalsAdded'] != null
          ? (map['animalsAdded'] as num).toInt()
          : null,
      deleted: map['deleted'] as bool? ?? false,
    );
  }

  ActivityLogRecord copyWith({
    String? id,
    String? animalId,
    DateTime? date,
    String? notes,
    double? cost,
    int? animalsAdded,
    bool? deleted,
  }) {
    return ActivityLogRecord(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      animalsAdded: animalsAdded ?? this.animalsAdded,
      deleted: deleted ?? this.deleted,
    );
  }
}
