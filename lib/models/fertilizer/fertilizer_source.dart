import 'package:flutter/foundation.dart';

@immutable
class FertilizerSource {
  final String id;
  final String organization; // e.g. 'FAO', 'EMBRAPA', 'KALRO', 'USDA / Univ Extension', 'ARC South Africa'
  final String title;
  final String country;
  final int year;
  final String? url;
  final String? notes;
  final bool isVerified;
  final DateTime? lastReviewed;

  const FertilizerSource({
    required this.id,
    required this.organization,
    required this.title,
    required this.country,
    this.year = 2024,
    this.url,
    this.notes,
    this.isVerified = true,
    this.lastReviewed,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'organization': organization,
        'title': title,
        'country': country,
        'year': year,
        'url': url,
        'notes': notes,
        'isVerified': isVerified,
        'lastReviewed': lastReviewed?.toIso8601String(),
      };

  factory FertilizerSource.fromMap(Map<String, dynamic> map, {String? id}) {
    return FertilizerSource(
      id: id ?? map['id'] ?? '',
      organization: map['organization'] ?? 'Agronomic Research Institute',
      title: map['title'] ?? '',
      country: map['country'] ?? 'Global',
      year: (map['year'] as num?)?.toInt() ?? 2024,
      url: map['url'],
      notes: map['notes'],
      isVerified: map['isVerified'] ?? true,
      lastReviewed: map['lastReviewed'] != null
          ? DateTime.tryParse(map['lastReviewed'])
          : null,
    );
  }
}
