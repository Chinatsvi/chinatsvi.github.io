import 'package:flutter/foundation.dart';

enum CropCategory {
  fieldCrop,
  vegetable,
  fruit,
  treeAndPerennial,
  herbAndSpecialty,
}

extension CropCategoryExtension on CropCategory {
  String get displayName {
    switch (this) {
      case CropCategory.fieldCrop:
        return 'Field Crops';
      case CropCategory.vegetable:
        return 'Vegetables';
      case CropCategory.fruit:
        return 'Fruit Crops';
      case CropCategory.treeAndPerennial:
        return 'Tree & Perennial Crops';
      case CropCategory.herbAndSpecialty:
        return 'Herbs & Specialty Crops';
    }
  }

  String get emoji {
    switch (this) {
      case CropCategory.fieldCrop:
        return '🌾';
      case CropCategory.vegetable:
        return '🥬';
      case CropCategory.fruit:
        return '🍎';
      case CropCategory.treeAndPerennial:
        return '🌳';
      case CropCategory.herbAndSpecialty:
        return '🌿';
    }
  }
}

@immutable
class FertilizerCrop {
  final String id;
  final String name;
  final String scientificName;
  final CropCategory category;
  final String iconEmoji;
  final List<String> defaultStages;
  final List<String> supportedProductionSystems;
  final bool requiresYieldTarget;
  final double defaultYieldTarget;
  final String yieldUnit;
  final bool active;

  const FertilizerCrop({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    this.iconEmoji = '🌱',
    this.defaultStages = const [],
    this.supportedProductionSystems = const ['Rain-fed', 'Irrigated'],
    this.requiresYieldTarget = false,
    this.defaultYieldTarget = 0.0,
    this.yieldUnit = 'tonnes/ha',
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'scientificName': scientificName,
        'category': category.name,
        'iconEmoji': iconEmoji,
        'defaultStages': defaultStages,
        'supportedProductionSystems': supportedProductionSystems,
        'requiresYieldTarget': requiresYieldTarget,
        'defaultYieldTarget': defaultYieldTarget,
        'yieldUnit': yieldUnit,
        'active': active,
      };

  factory FertilizerCrop.fromMap(Map<String, dynamic> map, {String? id}) {
    return FertilizerCrop(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      category: CropCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => CropCategory.fieldCrop,
      ),
      iconEmoji: map['iconEmoji'] ?? '🌱',
      defaultStages: List<String>.from(map['defaultStages'] ?? []),
      supportedProductionSystems: List<String>.from(
        map['supportedProductionSystems'] ?? ['Rain-fed', 'Irrigated'],
      ),
      requiresYieldTarget: map['requiresYieldTarget'] ?? false,
      defaultYieldTarget:
          (map['defaultYieldTarget'] as num?)?.toDouble() ?? 0.0,
      yieldUnit: map['yieldUnit'] ?? 'tonnes/ha',
      active: map['active'] ?? true,
    );
  }
}

@immutable
class FertilizerCropStage {
  final String id;
  final String cropId;
  final String stageName;
  final int order;
  final String description;
  final bool active;

  const FertilizerCropStage({
    required this.id,
    required this.cropId,
    required this.stageName,
    required this.order,
    this.description = '',
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'cropId': cropId,
        'stageName': stageName,
        'order': order,
        'description': description,
        'active': active,
      };

  factory FertilizerCropStage.fromMap(Map<String, dynamic> map, {String? id}) {
    return FertilizerCropStage(
      id: id ?? map['id'] ?? '',
      cropId: map['cropId'] ?? '',
      stageName: map['stageName'] ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      description: map['description'] ?? '',
      active: map['active'] ?? true,
    );
  }
}
