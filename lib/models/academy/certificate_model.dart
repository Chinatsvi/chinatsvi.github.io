import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String id;
  final String certificateNumber; // e.g. AGRI-2026-TOMATO-8491
  final String courseId;
  final String courseTitle;
  final String userId;
  final String userName;
  final DateTime issuedAt;
  final int scorePercentage;
  final String badgeName;
  final String? certificateUrl; // URL if PDF/image uploaded or rendered
  final bool isExternalUploaded;
  final String? externalIssuer;
  final String? externalDescription;
  final String? instructorName;

  CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    required this.userName,
    required this.issuedAt,
    this.scorePercentage = 100,
    this.badgeName = '🌱 Academy Graduate',
    this.certificateUrl,
    this.isExternalUploaded = false,
    this.externalIssuer,
    this.externalDescription,
    this.instructorName = 'AgriBase Farming Academy',
  });

  factory CertificateModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CertificateModel.fromMap(data, doc.id);
  }

  factory CertificateModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CertificateModel(
      id: id,
      certificateNumber: map['certificateNumber']?.toString() ?? 'AGRI-CERT-$id',
      courseId: map['courseId']?.toString() ?? '',
      courseTitle: map['courseTitle']?.toString() ?? 'AgriBase Course',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'Farmer',
      issuedAt: parseDate(map['issuedAt']),
      scorePercentage: (map['scorePercentage'] as num?)?.toInt() ?? 100,
      badgeName: map['badgeName']?.toString() ?? '🌱 Academy Graduate',
      certificateUrl: map['certificateUrl']?.toString(),
      isExternalUploaded: map['isExternalUploaded'] ?? false,
      externalIssuer: map['externalIssuer']?.toString(),
      externalDescription: map['externalDescription']?.toString(),
      instructorName: map['instructorName']?.toString() ?? 'AgriBase Farming Academy',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'certificateNumber': certificateNumber,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'userId': userId,
      'userName': userName,
      'issuedAt': issuedAt,
      'scorePercentage': scorePercentage,
      'badgeName': badgeName,
      if (certificateUrl != null) 'certificateUrl': certificateUrl,
      'isExternalUploaded': isExternalUploaded,
      if (externalIssuer != null) 'externalIssuer': externalIssuer,
      if (externalDescription != null) 'externalDescription': externalDescription,
      'instructorName': instructorName,
    };
  }
}
