/// Professional time formatter for comments and replies
/// Shows relative time like "2 minutes ago", "1 hour ago", "3 days ago", etc.
class TimeFormatter {
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  /// Format time with "now" for very recent times
  static String formatTimeWithNow(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 30) {
      return 'now';
    }
    return formatTime(dateTime);
  }

  /// Short format for compact displays (e.g., "2m", "1h", "3d")
  static String formatShortTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }

  /// Detailed format with exact time for older posts
  static String formatDetailedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      // For same day, show time
      return 'today at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 2) {
      return 'yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return formatTime(dateTime);
    } else {
      // For older posts, show date
      return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
  }

  /// Format time for chat/conversation style
  static String formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (now.day == dateTime.day &&
        now.month == dateTime.month &&
        now.year == dateTime.year) {
      return _formatTime(dateTime);
    } else if (difference.inDays < 7) {
      return formatTime(dateTime);
    } else {
      return _formatDate(dateTime);
    }
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatDate(DateTime dateTime) {
    final day = dateTime.day;
    final month = _getMonthName(dateTime.month);
    final year = dateTime.year;

    if (dateTime.year == DateTime.now().year) {
      return '$month $day';
    } else {
      return '$month $day, $year';
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Check if a timestamp is recent (less than 24 hours)
  static bool isRecent(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    return difference.inHours < 24;
  }

  /// Get relative time with color coding for UI
  static TimeWithColor getTimeWithColor(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    String timeText;
    ColorType colorType;

    if (difference.inMinutes < 1) {
      timeText = 'now';
      colorType = ColorType.green; // Very recent - green
    } else if (difference.inHours < 1) {
      timeText = '${difference.inMinutes}m';
      colorType = ColorType.blue; // Recent - blue
    } else if (difference.inDays < 1) {
      timeText = '${difference.inHours}h';
      colorType = ColorType.blue; // Today - blue
    } else if (difference.inDays < 7) {
      timeText = '${difference.inDays}d';
      colorType = ColorType.grey; // This week - grey
    } else {
      timeText = formatShortTime(dateTime);
      colorType = ColorType.lightGrey; // Older - light grey
    }

    return TimeWithColor(timeText, colorType);
  }
}

/// Data class for time with color information
class TimeWithColor {
  final String text;
  final ColorType colorType;

  const TimeWithColor(this.text, this.colorType);
}

enum ColorType { green, blue, grey, lightGrey }

/// Extension for ColorType to get actual colors
extension ColorTypeExtension on ColorType {
  String get colorName {
    switch (this) {
      case ColorType.green:
        return 'Colors.green';
      case ColorType.blue:
        return 'Colors.blue';
      case ColorType.grey:
        return 'Colors.grey';
      case ColorType.lightGrey:
        return 'Colors.grey[600]';
    }
  }
}
