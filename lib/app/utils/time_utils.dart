import 'package:intl/intl.dart';

class TimeUtils {
  static String formatTimestamp(DateTime time) {
    return DateFormat('dd MMM yyyy, HH:mm').format(time);
  }

  static String timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(time);
  }
}