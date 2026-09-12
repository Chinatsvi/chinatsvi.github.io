import 'package:flutter/foundation.dart';

enum FertilizerForm {
  granular,
  prilled,
  liquid,
  waterSoluble,
  organicCompost,
  foliar,
}

extension FertilizerFormExtension on FertilizerForm {
  String get displayName {
    switch (this) {
      case FertilizerForm.granular:
        return 'Granular';
      case FertilizerForm.prilled:
        return 'Prilled';
      case FertilizerForm.liquid:
        return 'Liquid';
      case FertilizerForm.waterSoluble:
        return 'Water Soluble';
      case FertilizerForm.organicCompost:
        return 'Organic / Compost';
      case FertilizerForm.foliar:
        return 'Foliar Spray';
    }
  }
}

@immutable
class FertilizerProduct {
  final String id;
  final String name;
  final String? manufacturer;
  final String countryCode; // ISO country code or 'GLOBAL'
  final String countryName;
  final double nPercent; // Nitrogen %
  final double pPercent; // Phosphate (P2O5) %
  final double kPercent; // Potash (K2O) %
  final double sPercent; // Sulfur %
  final double caPercent; // Calcium %
  final double mgPercent; // Magnesium %
  final Map<String, double> micronutrients; // e.g. {'Zn': 0.5, 'B': 0.2}
  final FertilizerForm physicalForm;
  final double packageSize; // e.g. 50.0, 25.0, 5.0, 1.0
  final String packageUnit; // 'kg', 'L'
  final String? usageNotes;
  final bool active;

  const FertilizerProduct({
    required this.id,
    required this.name,
    this.manufacturer,
    this.countryCode = 'GLOBAL',
    this.countryName = 'Global',
    this.nPercent = 0.0,
    this.pPercent = 0.0,
    this.kPercent = 0.0,
    this.sPercent = 0.0,
    this.caPercent = 0.0,
    this.mgPercent = 0.0,
    this.micronutrients = const {},
    this.physicalForm = FertilizerForm.granular,
    this.packageSize = 50.0,
    this.packageUnit = 'kg',
    this.usageNotes,
    this.active = true,
  });

  String get formulaGrade {
    final n = nPercent % 1 == 0 ? nPercent.toInt().toString() : nPercent.toStringAsFixed(1);
    final p = pPercent % 1 == 0 ? pPercent.toInt().toString() : pPercent.toStringAsFixed(1);
    final k = kPercent % 1 == 0 ? kPercent.toInt().toString() : kPercent.toStringAsFixed(1);
    var grade = '$n-$p-$k';
    if (sPercent > 0) {
      final s = sPercent % 1 == 0 ? sPercent.toInt().toString() : sPercent.toStringAsFixed(1);
      grade += ' + ${s}S';
    }
    return grade;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'manufacturer': manufacturer,
        'countryCode': countryCode,
        'countryName': countryName,
        'nPercent': nPercent,
        'pPercent': pPercent,
        'kPercent': kPercent,
        'sPercent': sPercent,
        'caPercent': caPercent,
        'mgPercent': mgPercent,
        'micronutrients': micronutrients,
        'physicalForm': physicalForm.name,
        'packageSize': packageSize,
        'packageUnit': packageUnit,
        'usageNotes': usageNotes,
        'active': active,
      };

  factory FertilizerProduct.fromMap(Map<String, dynamic> map, {String? id}) {
    return FertilizerProduct(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      manufacturer: map['manufacturer'],
      countryCode: map['countryCode'] ?? 'GLOBAL',
      countryName: map['countryName'] ?? 'Global',
      nPercent: (map['nPercent'] as num?)?.toDouble() ?? 0.0,
      pPercent: (map['pPercent'] as num?)?.toDouble() ?? 0.0,
      kPercent: (map['kPercent'] as num?)?.toDouble() ?? 0.0,
      sPercent: (map['sPercent'] as num?)?.toDouble() ?? 0.0,
      caPercent: (map['caPercent'] as num?)?.toDouble() ?? 0.0,
      mgPercent: (map['mgPercent'] as num?)?.toDouble() ?? 0.0,
      micronutrients: (map['micronutrients'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          const {},
      physicalForm: FertilizerForm.values.firstWhere(
        (e) => e.name == map['physicalForm'],
        orElse: () => FertilizerForm.granular,
      ),
      packageSize: (map['packageSize'] as num?)?.toDouble() ?? 50.0,
      packageUnit: map['packageUnit'] ?? 'kg',
      usageNotes: map['usageNotes'],
      active: map['active'] ?? true,
    );
  }
}
