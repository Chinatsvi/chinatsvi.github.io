class Group {
  final String id;
  final String name;
  final String description;
  final String coverPhoto;   // ✅ renamed for consistency
  final List<String> members;
  final String createdBy;    // ✅ renamed for consistency

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.coverPhoto,
    required this.members,
    required this.createdBy,
  });

  factory Group.fromMap(String id, Map<String, dynamic> data) {
    return Group(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      coverPhoto: data['cover_photo'] ?? '',   // ✅ matches Firestore
      members: List<String>.from(data['members'] ?? []),
      createdBy: data['created_by'] ?? '',     // ✅ matches Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'cover_photo': coverPhoto,   // ✅ consistent
      'members': members,
      'created_by': createdBy,     // ✅ consistent
    };
  }
}