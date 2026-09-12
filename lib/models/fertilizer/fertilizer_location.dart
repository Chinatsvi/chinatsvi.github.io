import 'package:flutter/foundation.dart';

@immutable
class FertilizerCountry {
  final String code; // e.g. 'ZW', 'BR', 'KE', 'ZA', 'US', 'IN', 'NG', 'GH', 'TZ', 'ET', 'UG', 'ZM'
  final String name;
  final String flagEmoji;
  final String defaultAreaUnit; // 'Hectares', 'Acres'
  final double defaultBagSizeKg; // e.g. 50.0, 25.0
  final List<String> regions;
  final bool active;

  const FertilizerCountry({
    required this.code,
    required this.name,
    required this.flagEmoji,
    this.defaultAreaUnit = 'Hectares',
    this.defaultBagSizeKg = 50.0,
    this.regions = const [],
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'flagEmoji': flagEmoji,
        'defaultAreaUnit': defaultAreaUnit,
        'defaultBagSizeKg': defaultBagSizeKg,
        'regions': regions,
        'active': active,
      };

  factory FertilizerCountry.fromMap(Map<String, dynamic> map, {String? code}) {
    return FertilizerCountry(
      code: code ?? map['code'] ?? '',
      name: map['name'] ?? '',
      flagEmoji: map['flagEmoji'] ?? '🌍',
      defaultAreaUnit: map['defaultAreaUnit'] ?? 'Hectares',
      defaultBagSizeKg: (map['defaultBagSizeKg'] as num?)?.toDouble() ?? 50.0,
      regions: List<String>.from(map['regions'] ?? []),
      active: map['active'] ?? true,
    );
  }
}

@immutable
class FertilizerRegion {
  final String id;
  final String countryCode;
  final String countryName;
  final String regionName; // Province / State / Natural Region
  final String? agroEcologicalZone;
  final String? climateSummary;
  final List<String> districts;
  final bool active;

  const FertilizerRegion({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.regionName,
    this.agroEcologicalZone,
    this.climateSummary,
    this.districts = const [],
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'regionName': regionName,
        'agroEcologicalZone': agroEcologicalZone,
        'climateSummary': climateSummary,
        'districts': districts,
        'active': active,
      };

  factory FertilizerRegion.fromMap(Map<String, dynamic> map, {String? id}) {
    return FertilizerRegion(
      id: id ?? map['id'] ?? '',
      countryCode: map['countryCode'] ?? '',
      countryName: map['countryName'] ?? '',
      regionName: map['regionName'] ?? '',
      agroEcologicalZone: map['agroEcologicalZone'],
      climateSummary: map['climateSummary'],
      districts: List<String>.from(map['districts'] ?? []),
      active: map['active'] ?? true,
    );
  }
}

@immutable
class FertilizerLocationQuery {
  final String? countryName;
  final String? countryCode;
  final String? regionName;
  final String? districtName;
  final double? latitude;
  final double? longitude;
  final String? agroEcologicalZone;

  const FertilizerLocationQuery({
    this.countryName,
    this.countryCode,
    this.regionName,
    this.districtName,
    this.latitude,
    this.longitude,
    this.agroEcologicalZone,
  });

  String get displayName {
    final parts = [
      if (districtName != null && districtName!.isNotEmpty) districtName!,
      if (regionName != null && regionName!.isNotEmpty) regionName!,
      if (countryName != null && countryName!.isNotEmpty) countryName!,
    ];
    if (parts.isEmpty) {
      if (latitude != null && longitude != null) {
        return 'GPS (${latitude!.toStringAsFixed(2)}, ${longitude!.toStringAsFixed(2)})';
      }
      return 'Global / Unspecified';
    }
    return parts.join(', ');
  }
}
