enum ReactionType { like, love, laugh, angry, sad, wow }

extension ReactionTypeExtension on ReactionType {
  String get name {
    switch (this) {
      case ReactionType.like:
        return 'like';
      case ReactionType.love:
        return 'love';
      case ReactionType.laugh:
        return 'laugh';
      case ReactionType.angry:
        return 'angry';
      case ReactionType.sad:
        return 'sad';
      case ReactionType.wow:
        return 'wow';
    }
  }

  static ReactionType fromString(String value) {
    return ReactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReactionType.like,
    );
  }
}
