import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCacheService {
  static const String _boxName = 'profile_cache';
  static Box<String>? _box;

  static Future<void> init() async {
    _box = await _ensureBox();
  }

  static Future<Box<String>> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<String>(_boxName);
      return _box!;
    }
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  static Box<String>? _getBoxIfOpen() {
    if (_box != null && _box!.isOpen) return _box;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<String>(_boxName);
      return _box;
    }
    return null;
  }

  /// Cache user profile data
  static Future<void> cacheProfile(String userId, Map<String, dynamic> profileData) async {
    final box = await _ensureBox();
    await box.put(userId, _encodeData(profileData));
  }

  /// Get cached profile data
  static Map<String, dynamic>? getCachedProfile(String userId) {
    final box = _getBoxIfOpen();
    if (box == null) return null;
    final data = box.get(userId);
    if (data != null) {
      return _decodeData(data);
    }
    return null;
  }

  /// Check if profile is cached
  static bool isProfileCached(String userId) {
    final box = _getBoxIfOpen();
    if (box == null) return false;
    return box.containsKey(userId);
  }

  /// Clear all cached profiles
  static Future<void> clearCache() async {
    final box = await _ensureBox();
    await box.clear();
  }

  /// Clear specific profile
  static Future<void> clearProfile(String userId) async {
    final box = await _ensureBox();
    await box.delete(userId);
  }

  static String _encodeData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}|${_encodeValue(e.value)}').join(';;');
  }

  static Map<String, dynamic> _decodeData(String encoded) {
    final map = <String, dynamic>{};
    final entries = encoded.split(';;');
    for (final entry in entries) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        map[parts[0]] = _decodeValue(parts[1]);
      }
    }
    return map;
  }

  static String _encodeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return 'bool:$value';
    if (value is int) return 'int:$value';
    if (value is double) return 'double:$value';
    if (value is Timestamp) return 'timestamp:${value.millisecondsSinceEpoch}';
    return 'string:$value';
  }

  static dynamic _decodeValue(String encoded) {
    if (encoded == 'null') return null;
    if (encoded.startsWith('bool:')) return encoded.substring(5) == 'true';
    if (encoded.startsWith('int:')) return int.parse(encoded.substring(4));
    if (encoded.startsWith('double:')) return double.parse(encoded.substring(7));
    if (encoded.startsWith('timestamp:')) {
      return Timestamp.fromMillisecondsSinceEpoch(int.parse(encoded.substring(10)));
    }
    if (encoded.startsWith('string:')) return encoded.substring(7);
    return encoded;
  }
}
