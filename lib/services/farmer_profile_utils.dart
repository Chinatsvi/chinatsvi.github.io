import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, Object?> buildFarmerProfilePayload({
  required String uid,
  required String userName,
  required String email,
  required String profilePic,
  required String coverPhoto,
  String location = '',
  String bio = '',
  String phone = '',
  String work = '',
  String education = '',
  String farmType = '',
  String accountTypeName = 'basic',
  Map<String, dynamic>? existingData,
  bool includeCreatedAt = true,
}) {
  final existing = existingData ?? const <String, dynamic>{};

  List<dynamic> _listField(String key, [List<dynamic>? fallback]) {
    final value = existing[key];
    if (value is List) return List<dynamic>.from(value);
    if (fallback != null) return List<dynamic>.from(fallback);
    return <dynamic>[];
  }

  String _stringField(String key, String fallback) {
    final value = existing[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  final payload = <String, Object?>{
    'id': uid,
    'user_name': _stringField('user_name', userName),
    'email': _stringField('email', email),
    'location': _stringField('location', location),
    'bio': _stringField('bio', bio),
    'phone': _stringField('phone', phone),
    'work': _stringField('work', work),
    'education': _stringField('education', education),
    'profile_pic': _stringField('profile_pic', profilePic),
    'cover_photo': _stringField('cover_photo', coverPhoto),
    'farmType': _stringField('farmType', farmType),
    'accountType': _stringField('accountType', accountTypeName),
    'followers': _listField('followers', const []),
    'following': _listField('following', const []),
    'crops': _listField('crops', const []),
    'updated_at': FieldValue.serverTimestamp(),
    'active': existing['active'] ?? true,
  };

  if (includeCreatedAt) {
    payload['created_at'] = FieldValue.serverTimestamp();
  }

  return payload;
}
