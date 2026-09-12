import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCacheService {
  static const String _boxName = 'post_cache';
  static const int _maxCachedPosts = 100;
  static Box<dynamic>? _box;

  static Future<void> init() async {
    _box = await _ensureBox();
  }

  static Future<Box<dynamic>> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<dynamic>(_boxName);
      return _box!;
    }
    _box = await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  static Box<dynamic>? _getBoxIfOpen() {
    if (_box != null && _box!.isOpen) return _box;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<dynamic>(_boxName);
      return _box;
    }
    // Try to open the box if it exists but isn't open
    // This improves offline support when cache exists but box wasn't initialized
    try {
      if (Hive.isAdapterRegistered(0)) {
        _box = Hive.box<dynamic>(_boxName);
        if (_box?.isOpen ?? false) {
          return _box;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Cache a single post
  static Future<void> cachePost(
    String postId,
    Map<String, dynamic> postData, {
    String? accountKey,
  }) async {
    final box = await _ensureBox();
    await box.put(_cacheKey(postId, accountKey), _encodeData(postData));
  }

  /// Cache multiple posts
  static Future<void> cachePosts(
    Map<String, Map<String, dynamic>> posts, {
    String? accountKey,
  }) async {
    final box = await _ensureBox();
    for (final entry in posts.entries) {
      await box.put(_cacheKey(entry.key, accountKey), _encodeData(entry.value));
    }
    await _pruneOldEntries();
  }

  /// Get cached post
  static Map<String, dynamic>? getCachedPost(
    String postId, {
    String? accountKey,
  }) {
    final box = _getBoxIfOpen();
    if (box == null) return null;
    final data = box.get(_cacheKey(postId, accountKey));
    if (data is String) {
      return _decodeData(data);
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return _castMapKeys(data);
    }
    return null;
  }

  /// Get all cached posts
  static Map<String, Map<String, dynamic>> getAllCachedPosts({
    String? accountKey,
  }) {
    final box = _getBoxIfOpen();
    if (box == null) return <String, Map<String, dynamic>>{};
    final posts = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(_accountPrefix(accountKey))) {
        continue;
      }
      final postId = key.substring(_accountPrefix(accountKey).length);
      final data = box.get(key);
      if (data is String) {
        posts[postId] = _decodeData(data);
      } else if (data is Map<String, dynamic>) {
        posts[postId] = data;
      } else if (data is Map) {
        posts[postId] = _castMapKeys(data);
      }
    }
    return posts;
  }

  static Map<String, dynamic> _castMapKeys(Map data) {
    final normalized = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      if (value is Map) {
        normalized[key] = _castMapKeys(value);
      } else if (value is List) {
        normalized[key] = value.map((item) {
          if (item is Map) return _castMapKeys(item);
          return item;
        }).toList();
      } else {
        normalized[key] = value;
      }
    }
    return normalized;
  }

  /// Check if post is cached
  static bool isPostCached(String postId, {String? accountKey}) {
    final box = _getBoxIfOpen();
    if (box == null) return false;
    return box.containsKey(_cacheKey(postId, accountKey));
  }

  /// Clear all cached posts
  static Future<void> clearCache() async {
    final box = await _ensureBox();
    await box.clear();
  }

  /// Clear specific post
  static Future<void> clearPost(String postId, {String? accountKey}) async {
    final box = await _ensureBox();
    await box.delete(_cacheKey(postId, accountKey));
  }

  static String _accountPrefix(String? accountKey) =>
      'account_${accountKey ?? 'anonymous'}::';

  static String _cacheKey(String postId, String? accountKey) =>
      '${_accountPrefix(accountKey)}$postId';

  static Future<void> _pruneOldEntries() async {
    final box = await _ensureBox();
    final keys = box.keys.whereType<String>().toList();
    if (keys.length <= _maxCachedPosts) return;

    final toRemove = keys.take(keys.length - _maxCachedPosts).toList();
    for (final key in toRemove) {
      await box.delete(key);
    }
  }

  static String _encodeData(Map<String, dynamic> data) {
    return jsonEncode(_normalizeValues(data));
  }

  static Map<String, dynamic> _decodeData(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return _castMapKeys(decoded);
      }
    } catch (_) {
      // Fallback to legacy delimiter format for older cache entries.
    }
    return _decodeLegacyData(encoded);
  }

  static Map<String, dynamic> _decodeLegacyData(String encoded) {
    final map = <String, dynamic>{};
    final entries = encoded.split(';;');
    for (final entry in entries) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        map[parts[0]] = _decodeLegacyValue(parts[1]);
      }
    }
    return map;
  }

  static dynamic _decodeLegacyValue(String encoded) {
    if (encoded == 'null') return null;
    if (encoded.startsWith('bool:')) return encoded.substring(5) == 'true';
    if (encoded.startsWith('int:')) return int.tryParse(encoded.substring(4));
    if (encoded.startsWith('double:')) return double.tryParse(encoded.substring(7));
    if (encoded.startsWith('timestamp:')) {
      return Timestamp.fromMillisecondsSinceEpoch(int.parse(encoded.substring(10)));
    }
    if (encoded.startsWith('list:')) {
      final listStr = encoded.substring(5);
      return listStr.split(',,').map(_decodeLegacyValue).toList();
    }
    if (encoded.startsWith('string:')) return encoded.substring(7);
    return encoded;
  }

  static Map<String, dynamic> _normalizeValues(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      }
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Timestamp) return item.millisecondsSinceEpoch;
          if (item is DateTime) return item.toIso8601String();
          return item;
        }).toList());
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _normalizeValues(value));
      }
      return MapEntry(key, value);
    });
  }
}
