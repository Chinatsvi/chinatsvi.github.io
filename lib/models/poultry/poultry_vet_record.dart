import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryVetRecord {
  final String id;
  final String batchId;
  final DateTime visitDate;
  final String reason; // vaccination, treatment, checkup
  final String? diagnosis;
  final String? treatment;
  final double? cost; // cost of vet visit, medicines, etc.

  const PoultryVetRecord({
    required this.id,
    required this.batchId,
    required this.visitDate,
    required this.reason,
    this.diagnosis,
    this.treatment,
    this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'visitDate': Timestamp.fromDate(visitDate),
      'reason': reason,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'cost': cost,
    };
  }

  factory PoultryVetRecord.fromMap(Map<String, dynamic> map) {
    return PoultryVetRecord(
      id: map['id'],
      batchId: map['batchId'],
      visitDate: (map['visitDate'] as Timestamp).toDate(),
      reason: map['reason'],
      diagnosis: map['diagnosis'],
      treatment: map['treatment'],
      cost: (map['cost'] as num?)?.toDouble(),
    );
  }
}
