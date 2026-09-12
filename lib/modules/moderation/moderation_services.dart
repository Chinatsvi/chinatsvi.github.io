import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ModerationService {
  static Future<bool> checkContent({
    required String text,
    required XFile? file,
    required String type,
  }) async {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('hate') || lowerText.contains('kill')) {
      debugPrint('⚠️ Text flagged by moderation');
      return false;
    }

    if (file != null && (type == 'image' || type == 'video')) {
      try {
        final fileSize = await file.length();
        if (fileSize > 20 * 1024 * 1024) {
          debugPrint('⚠️ File too large: ${fileSize / (1024 * 1024)} MB');
          return false;
        }
        debugPrint('✅ Media passed simulated moderation');
      } catch (e) {
        debugPrint('❌ Error checking file size: $e');
        return false;
      }
    }

    return true;
  }
}