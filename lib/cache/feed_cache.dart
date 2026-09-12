import 'package:hive/hive.dart';
import 'package:agribased/models/post_model.dart';

class FeedCache {
  static const String boxName = 'feed_posts';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<Post> loadPosts({String accountKey = 'anonymous'}) {
    final box = Hive.box(boxName);
    final list = box.get('posts_$accountKey', defaultValue: []) as List;
    return list.cast<Post>();
  }

  static Future<void> savePosts(
    List<Post> posts, {
    String accountKey = 'anonymous',
  }) async {
    final box = Hive.box(boxName);
    await box.put('posts_$accountKey', posts);
  }
}
