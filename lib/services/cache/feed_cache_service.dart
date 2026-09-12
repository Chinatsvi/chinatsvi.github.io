import 'package:hive_flutter/hive_flutter.dart';

class FeedCacheService {
  static const String _boxName = 'feed_cache';
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
    return null;
  }

  /// Cache the ordered list of feed item ids with minimal metadata
  static Future<void> cacheFeedList(
    List<Map<String, dynamic>> items, {
    String? accountKey,
  }) async {
    final box = await _ensureBox();
    // store as list of maps
    await box.put(_feedListKey(accountKey), items);
  }

  static List<Map<String, dynamic>> getFeedList({String? accountKey}) {
    final box = _getBoxIfOpen();
    if (box == null) return <Map<String, dynamic>>[];
    final data = box.get(_feedListKey(accountKey));
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map>());
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> clearCache() async {
    final box = await _ensureBox();
    await box.clear();
  }

  static Future<void> addOrUpdateFeedItem(
    Map<String, dynamic> item, {
    String? accountKey,
  }) async {
    final list = getFeedList(accountKey: accountKey);
    // remove existing with same postId
    list.removeWhere((e) => e['postId'] == item['postId']);
    list.insert(0, item);
    await cacheFeedList(list, accountKey: accountKey);
  }

  static Future<void> removeFeedItem(
    String postId, {
    String? accountKey,
  }) async {
    final list = getFeedList(accountKey: accountKey);
    list.removeWhere((e) => e['postId'] == postId);
    await cacheFeedList(list, accountKey: accountKey);
  }

  static String _feedListKey(String? accountKey) =>
      'feed_list_${accountKey ?? 'anonymous'}';
}
