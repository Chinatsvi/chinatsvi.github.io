class UserCache {
  static final Map<String, String> _names = {};

  static String? getName(String uid) => _names[uid];

  static void setName(String uid, String name) {
    if (uid.isNotEmpty && name.isNotEmpty) {
      _names[uid] = name;
    }
  }
}
