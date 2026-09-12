import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'build_config_service.dart';

/// Enhanced AI Content Moderation Service
/// Uses Gemini via Google Generative Language API for moderation.
class AIContentModerationService {
  static const String _geminiModel = 'gemini-2.5-flash';
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  static String get _geminiApiKey => BuildConfigService.geminiApiKey;
  static String get _moderationWorkerUrl => BuildConfigService.moderationWorkerUrl;

  static const List<String> supportedCategories = [
    'harmful',
    'violence',
    'hate',
    'hateSpeech',
    'sexual',
    'sexualContent',
    'nudity',
    'prohibitedGoods',
    'self-harm',
    'spam',
  ];

  static const String _classificationPrompt =
      'You are an AI content moderator for AgriBase, an agricultural community platform. '
      'Agricultural topics (farming, crops, livestock breeding, pesticides, weed control, herbicides, fertilizers, animal feed, veterinary medicine, farmer business) are SAFE and allowed. '
      'Respond with exactly one valid JSON object and nothing else. '
      'The object must include keys "label", "confidence", "categories", and "reason". '
      'Example: {"label":"HARMFUL","confidence":0.95,"categories":["sexualContent"],"reason":"explicit pornography"}. '
      'The label must be either "HARMFUL" or "SAFE". '
      'Do not include any explanation, markdown, extra keys, or text outside the JSON object.';

  /// Analyze content for harmful material - NON-STREAMING approach
  /// Waits for complete AI response before returning results
  static Future<ModerationResult> moderateContent(
    String content, {
    String contentType = 'post',
    List<String>? mediaUrls,
    String? imageUrl,
  }) async {
    final effectiveMedia = <String>[
      if (imageUrl != null && imageUrl.trim().isNotEmpty) imageUrl.trim(),
      if (mediaUrls != null)
        ...mediaUrls.where((u) => u.trim().isNotEmpty).map((u) => u.trim()),
    ];

    if (content.trim().isEmpty && effectiveMedia.isEmpty) {
      return const ModerationResult(
        isFlagged: false,
        categories: {},
        confidenceScores: {},
        reason: 'Empty content',
      );
    }

    try {
      if (BuildConfigService.hasModerationWorkerUrl) {
        final workerResult = await _moderateViaCloudflareWorker(
          content,
          contentType: contentType,
          images: effectiveMedia,
        );
        if (workerResult != null) {
          return workerResult;
        }
      }

      if (_geminiApiKey.isEmpty) {
        developer.log('❌ Gemini API key is missing', name: 'AIModeration');
        return _basicKeywordFilter(content);
      }

      developer.log('🤖 Starting Gemini content moderation analysis...', name: 'AIModeration');

      final uri = Uri.parse('$_geminiBaseUrl/$_geminiModel:generateContent?key=${Uri.encodeComponent(_geminiApiKey)}');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': _classificationPrompt},
                {'text': 'Content type: $contentType\nText: $content\nImages: ${effectiveMedia.join(", ")}'},
              ],
            }
          ],
          'temperature': 0,
          'candidateCount': 1,
          'maxOutputTokens': 200,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final moderationResult = _parseGeminiResponse(response.body);
        developer.log('✅ Gemini moderation complete. Flagged: ${moderationResult.isFlagged}', name: 'AIModeration');
        return moderationResult;
      }

      developer.log('❌ Gemini moderation failed: ${response.statusCode}', name: 'AIModeration');
      return _basicKeywordFilter(content);
    } catch (e) {
      developer.log('❌ AI moderation error: $e', name: 'AIModeration');
      return _basicKeywordFilter(content);
    }
  }

  static Future<ModerationResult?> _moderateViaCloudflareWorker(
    String content, {
    String contentType = 'post',
    List<String>? images,
  }) async {
    try {
      developer.log('🌐 Sending moderation request to Cloudflare worker (type: $contentType)', name: 'AIModeration');

      final uri = Uri.parse(_moderationWorkerUrl);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': content,
          'contentType': contentType,
          if (images != null && images.isNotEmpty) 'images': images,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        developer.log('❌ Cloudflare worker returned ${response.statusCode}', name: 'AIModeration');
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (payload['success'] != true) {
        developer.log('❌ Cloudflare worker error: ${payload['error']}', name: 'AIModeration');
        return null;
      }

      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        developer.log('❌ Cloudflare worker returned empty data', name: 'AIModeration');
        return null;
      }

      final label = data['label']?.toString().toUpperCase() ?? 'SAFE';
      final confidence = (data['confidence'] is num)
          ? (data['confidence'] as num).toDouble()
          : double.tryParse(data['confidence']?.toString() ?? '') ?? 0.85;
      final isFlagged = label == 'HARMFUL';
      final categories = <String, bool>{};

      final rawCategories = data['categories'];
      if (rawCategories is List) {
        for (final cat in rawCategories) {
          final catStr = cat?.toString().trim();
          if (catStr != null && catStr.isNotEmpty) {
            categories[catStr] = true;
          }
        }
      }

      if (isFlagged && categories.isEmpty) {
        categories['harmful'] = true;
      }

      final confidenceScores = <String, double>{};
      if (categories.isNotEmpty) {
        for (final key in categories.keys) {
          confidenceScores[key] = confidence;
        }
      } else {
        confidenceScores['harmful'] = confidence;
      }

      return ModerationResult(
        isFlagged: isFlagged,
        categories: categories,
        confidenceScores: confidenceScores,
        reason: data['reason']?.toString() ?? (isFlagged ? 'Harmful content detected' : 'Content approved'),
      );
    } catch (e) {
      developer.log('❌ Cloudflare moderation error: $e', name: 'AIModeration');
      return null;
    }
  }

  static ModerationResult _parseGeminiResponse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      final rawContent = candidates != null && candidates.isNotEmpty
          ? (candidates.first['content'] as String? ?? '')
          : '';

      final parsed = _extractJsonObject(rawContent);
      if (parsed == null) {
        throw Exception('Unable to parse Gemini moderation JSON output');
      }

      final label = parsed['label']?.toString().toUpperCase() ?? 'SAFE';
      final confidence = parsed['confidence'] is num
          ? (parsed['confidence'] as num).toDouble()
          : double.tryParse(parsed['confidence']?.toString() ?? '') ?? 0.85;
      final categoriesRaw = parsed['categories'];
      final categories = <String, bool>{};
      if (categoriesRaw is List) {
        for (final item in categoriesRaw) {
          final key = item?.toString();
          if (key != null && key.isNotEmpty) {
            categories[key] = true;
          }
        }
      }

      if (categories.isEmpty && label == 'HARMFUL') {
        categories['harmful'] = true;
      }

      final confidenceScores = <String, double>{};
      if (categories.isNotEmpty) {
        for (final key in categories.keys) {
          confidenceScores[key] = confidence;
        }
      } else {
        confidenceScores['harmful'] = confidence;
      }

      return ModerationResult(
        isFlagged: label == 'HARMFUL',
        categories: categories,
        confidenceScores: confidenceScores,
        reason: parsed['reason']?.toString() ?? (label == 'HARMFUL' ? 'Harmful content detected' : 'Content approved'),
      );
    } catch (e) {
      developer.log('❌ Failed to parse Gemini moderation output: $e', name: 'AIModeration');
      return _basicKeywordFilter('');
    }
  }

  static Map<String, dynamic>? _extractJsonObject(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll(RegExp(r'```'), '')
        .replaceAll('\r', '\n')
        .trim();

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (match == null) return null;

    try {
      return jsonDecode(match.group(0)!);
    } catch (_) {
      return null;
    }
  }

  /// Fallback basic keyword filter (when AI service fails)
  /// Uses strict whole-word patterns to avoid false positives on agricultural words
  static ModerationResult _basicKeywordFilter(String content) {
    final lowerContent = content.toLowerCase();

    // Check for explicit severe patterns with word boundaries
    final severePatterns = {
      'sexualContent': RegExp(r'\b(porn|porno|pornography|xxx|nsfw|nude|nudity|naked|genitals|masturbat\w*)\b', caseSensitive: false),
      'violence': RegExp(r'\b(kill you|murder you|terrorist attack|bombing|white supremacy)\b', caseSensitive: false),
      'prohibitedGoods': RegExp(r'\b(cocaine|heroin|crystal meth|fentanyl|crack cocaine)\b', caseSensitive: false),
      'spam': RegExp(r'\b(free money giveaway|send btc get double|ponzi scheme)\b', caseSensitive: false),
    };

    final flaggedCategories = <String, bool>{};
    for (final entry in severePatterns.entries) {
      if (entry.value.hasMatch(lowerContent)) {
        flaggedCategories[entry.key] = true;
      }
    }

    final isFlagged = flaggedCategories.isNotEmpty;
    return ModerationResult(
      isFlagged: isFlagged,
      categories: flaggedCategories,
      confidenceScores: {
        for (final k in flaggedCategories.keys) k: 1.0,
      },
      reason: isFlagged ? 'Prohibited content detected' : 'Content approved',
    );
  }

  /// Batch moderate multiple posts efficiently
  static Future<List<ModerationResult>> moderateBatch(List<String> contents) async {
    developer.log('📦 Starting batch moderation of ${contents.length} items', name: 'AIModeration');

    final futures = contents.map((content) => moderateContent(content)).toList();
    final batchResults = await Future.wait(futures);

    developer.log('✅ Batch moderation complete', name: 'AIModeration');
    return batchResults;
  }

  /// Check if content is safe for specific audience (e.g., all-ages)
  static Future<bool> isSafeForGeneralAudience(String content) async {
    final result = await moderateContent(content);

    final strictCategories = [
      'sexual',
      'sexual/minors',
      'violence/graphic',
      'self-harm',
      'hate/threatening',
    ];

    for (final category in strictCategories) {
      if (result.categories[category] == true) {
        return false;
      }
    }

    return true;
  }
}

/// Moderation result model
class ModerationResult {
  final bool isFlagged;
  final Map<String, bool> categories;
  final Map<String, double> confidenceScores;
  final String reason;

  const ModerationResult({
    required this.isFlagged,
    required this.categories,
    required this.confidenceScores,
    required this.reason,
  });

  /// Check if content violates any category
  bool violatesCategory(String category) {
    return categories[category] == true;
  }

  /// Get confidence score for a category
  double? getConfidence(String category) {
    return confidenceScores[category];
  }

  /// Check if content has high confidence violations
  bool get hasHighConfidenceViolations {
    return confidenceScores.values.any((score) => score > 0.8);
  }

  @override
  String toString() {
    return 'ModerationResult(flagged: $isFlagged, reason: $reason, categories: $categories)';
  }
}
