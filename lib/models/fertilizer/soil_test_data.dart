import 'package:flutter/foundation.dart';

@immutable
class SoilTestData {
  final bool hasSoilTest;
  final double? ph; // Soil pH (H2O or CaCl2)
  final double? nitrogenPpm; // Available N (NO3-N + NH4-N) ppm / mg/kg
  final double? phosphorusPpm; // Available P (Bray-1 / Mehlich-3 / Olsen) ppm
  final double? potassiumPpm; // Exchangeable K ppm
  final double? organicMatterPercent; // OM %
  final double? sulfurPpm; // SO4-S ppm
  final double? calciumPpm; // Exchangeable Ca ppm
  final double? magnesiumPpm; // Exchangeable Mg ppm
  final double? cec; // Cation Exchange Capacity (cmol(+)/kg or meq/100g)
  final String? soilTexture; // Sandy, Sandy Loam, Loam, Clay Loam, Clay

  const SoilTestData({
    this.hasSoilTest = false,
    this.ph,
    this.nitrogenPpm,
    this.phosphorusPpm,
    this.potassiumPpm,
    this.organicMatterPercent,
    this.sulfurPpm,
    this.calciumPpm,
    this.magnesiumPpm,
    this.cec,
    this.soilTexture,
  });

  bool get isEmpty =>
      !hasSoilTest ||
      (ph == null &&
          nitrogenPpm == null &&
          phosphorusPpm == null &&
          potassiumPpm == null &&
          organicMatterPercent == null);

  Map<String, dynamic> toMap() => {
        'hasSoilTest': hasSoilTest,
        'ph': ph,
        'nitrogenPpm': nitrogenPpm,
        'phosphorusPpm': phosphorusPpm,
        'potassiumPpm': potassiumPpm,
        'organicMatterPercent': organicMatterPercent,
        'sulfurPpm': sulfurPpm,
        'calciumPpm': calciumPpm,
        'magnesiumPpm': magnesiumPpm,
        'cec': cec,
        'soilTexture': soilTexture,
      };

  factory SoilTestData.fromMap(Map<String, dynamic> map) {
    return SoilTestData(
      hasSoilTest: map['hasSoilTest'] ?? false,
      ph: (map['ph'] as num?)?.toDouble(),
      nitrogenPpm: (map['nitrogenPpm'] as num?)?.toDouble(),
      phosphorusPpm: (map['phosphorusPpm'] as num?)?.toDouble(),
      potassiumPpm: (map['potassiumPpm'] as num?)?.toDouble(),
      organicMatterPercent:
          (map['organicMatterPercent'] as num?)?.toDouble(),
      sulfurPpm: (map['sulfurPpm'] as num?)?.toDouble(),
      calciumPpm: (map['calciumPpm'] as num?)?.toDouble(),
      magnesiumPpm: (map['magnesiumPpm'] as num?)?.toDouble(),
      cec: (map['cec'] as num?)?.toDouble(),
      soilTexture: map['soilTexture'],
    );
  }
}
