import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class EnhancedAiService {
  static EnhancedAiService? _instance;
  static EnhancedAiService get instance => _instance ??= EnhancedAiService._();

  EnhancedAiService._();

  static String _dayKey(DateTime date) =>
      date.toLocal().toIso8601String().split('T').first;

  static bool shouldResetUsage({
    required DateTime now,
    required DateTime lastResetAt,
  }) {
    final nowDay = _dayKey(now);
    final lastDay = _dayKey(lastResetAt);
    return nowDay != lastDay;
  }

  String _geminiApiKey = '';
  String _openAiApiKey = '';
  String _lastProviderError = '';

  // Preserve the model priority used by the known-working APK. If Google
  // retires one of these IDs, _discoverGeminiModels supplies live fallbacks.
  final List<String> _geminiModels = [
    'gemini-2.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static const String _usageKeyPrefix = 'ai_daily_usage_';
  static const String _lastUsageDateKeyPrefix = 'ai_last_usage_date_';
  static const String _uploadUsageKeyPrefix = 'ai_daily_upload_';
  static const String _bonusPointsKeyPrefix = 'ai_bonus_points_';
  static const String _anonymousUserIdKey = 'ai_anonymous_user_id';
  static const int _dailyLimit = 10;
  static const int _verifiedDailyLimit = 999999; // Unlimited for verified users
  static const int _dailyUploadLimit =
      3; // Max 3 uploads per day for regular users
  static const int _verifiedDailyUploadLimit =
      999999; // Unlimited for verified users
  static const int _uploadCost = 5; // Each upload costs 5 requests
  static const int _textCost = 1; // Each text message costs 1 request

  void initialize(String geminiKey, {String? userId, String? openAiKey}) {
    _geminiApiKey = geminiKey;
    _openAiApiKey = openAiKey ?? '';
    debugPrint('🤖 Chinatsvi AI Service initialized with Multi-Model Fallback');
    debugPrint(
      '🤖 Gemini Key: ${_geminiApiKey.isNotEmpty ? "✅ present (${_geminiApiKey.substring(0, 15)}...)" : "❌ MISSING"}',
    );
    debugPrint(
      '🤖 OpenAI Key: ${_openAiApiKey.isNotEmpty ? "✅ present (${_openAiApiKey.substring(0, 20)}...)" : "❌ not provided"}',
    );
    debugPrint(
      '🤖 Fallback chain: ${_geminiModels.join(" → ")} → OpenAI GPT-3.5',
    );
    debugPrint('🤖 User ID: ${userId ?? 'not provided'}');
  }

  /// 🔥 Diagnostic method - test all APIs and return detailed status
  Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};

    // Test Gemini models
    for (final model in _geminiModels) {
      try {
        final testEndpoint =
            "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey";
        final testBody = {
          "contents": [
            {
              "parts": [
                {"text": "Hi"},
              ],
            },
          ],
          "generationConfig": {"maxOutputTokens": 10},
        };

        final response = await http
            .post(
              Uri.parse(testEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(testBody),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          results['gemini_$model'] = {'status': '✅ OK', 'error': null};
        } else {
          final errorData = json.decode(response.body);
          results['gemini_$model'] = {
            'status': '❌ FAILED',
            'http_code': response.statusCode,
            'error': errorData['error']?['message'] ?? 'Unknown error',
          };
        }
      } catch (e) {
        results['gemini_$model'] = {'status': '❌ ERROR', 'error': e.toString()};
      }
    }

    // Test OpenAI
    if (_openAiApiKey.isNotEmpty && !_lastProviderError.contains('429')) {
      try {
        final response = await http
            .post(
              Uri.parse("https://api.openai.com/v1/chat/completions"),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_openAiApiKey',
              },
              body: json.encode({
                "model": "gpt-3.5-turbo",
                "messages": [
                  {"role": "user", "content": "Hi"},
                ],
                "max_tokens": 10,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          results['openai_gpt35'] = {'status': '✅ OK', 'error': null};
        } else {
          final errorData = json.decode(response.body);
          results['openai_gpt35'] = {
            'status': '❌ FAILED',
            'http_code': response.statusCode,
            'error': errorData['error']?['message'] ?? 'Unknown error',
          };
        }
      } catch (e) {
        results['openai_gpt35'] = {'status': '❌ ERROR', 'error': e.toString()};
      }
    } else {
      results['openai_gpt35'] = {'status': '⏭️ SKIPPED', 'error': 'No API key'};
    }

    return results;
  }

  /// Get daily upload limit based on verification status
  Future<int> _getDailyUploadLimit() async {
    final isVerified = await _isUserVerified();
    return isVerified ? _verifiedDailyUploadLimit : _dailyUploadLimit;
  }

  /// Check if user can make an upload
  Future<bool> canUpload() async {
    final uploadCount = await getUploadCount();
    final uploadLimit = await _getDailyUploadLimit();
    return uploadCount < uploadLimit;
  }

  /// Get current upload count for today
  Future<int> getUploadCount() async {
    try {
      final userId = await _getEffectiveUserId();

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastUsageDate =
          prefs.getString('$_lastUsageDateKeyPrefix$userId') ?? '';

      if (lastUsageDate != today) return 0;

      return prefs.getInt('$_uploadUsageKeyPrefix$userId') ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting upload count: $e');
      return 0;
    }
  }

  /// Public method - try non-streaming first to test
  Stream<String> streamResponse(
    String prompt, {
    List<String>? conversationHistory,
    File? attachment,
    String? attachmentType,
  }) async* {
    debugPrint('🤖 Prompt: $prompt');
    debugPrint('🤖 Attachment: ${attachment?.path}');
    debugPrint('🤖 Attachment Type: $attachmentType');

    try {
      await _ensureApiKeyLoaded();
      // Get the complete response first without streaming
      final response = await _getCompleteResponse(
        prompt,
        conversationHistory: conversationHistory,
        attachment: attachment,
        attachmentType: attachmentType,
      );
      yield response;
    } catch (e) {
      debugPrint('❌ All AI models failed: $e');
      // Show detailed error in debug builds for troubleshooting
      final errorStr = e.toString();
      if (errorStr.contains('429') ||
          errorStr.contains('quota') ||
          errorStr.contains('exhausted')) {
        yield "⚠️ AI quota exceeded.\n\nAll API keys have hit their free tier limits.\n\nTo fix this:\n1. Wait 24 hours for quotas to reset, OR\n2. Create a new Google AI Studio project with a new API key\n\n(Error: Rate limit exceeded)";
      } else if (errorStr.contains('400') || errorStr.contains('invalid')) {
        yield "⚠️ API key invalid or disabled.\n\nPlease check your API key in Google AI Studio.\n\n(Error: $errorStr)";
      } else {
        yield "⚠️ AI service unavailable.\n\nError: $errorStr";
      }
    }
  }

  Future<void> _ensureApiKeyLoaded() async {
    if (_geminiApiKey.trim().isNotEmpty || _openAiApiKey.trim().isNotEmpty) {
      return;
    }

    try {
      const channel = MethodChannel('com.chinatsvi.agribased/config');
      final nativeKey = await channel.invokeMethod<String>('getGeminiApiKey');
      if (nativeKey != null && nativeKey.trim().isNotEmpty) {
        _geminiApiKey = nativeKey.trim();
        debugPrint('🤖 Gemini key loaded lazily from Android BuildConfig');
      }
    } catch (e) {
      debugPrint('⚠️ Lazy Gemini key loading failed: $e');
    }
  }

  /// Get complete response with multi-model fallback
  Future<String> _getCompleteResponse(
    String prompt, {
    List<String>? conversationHistory,
    File? attachment,
    String? attachmentType,
  }) async {
    _lastProviderError = '';
    if (_geminiApiKey.trim().isEmpty && _openAiApiKey.trim().isEmpty) {
      throw Exception(
        'No AI API key configured. Build with --dart-define=GEMINI_API_KEY=<key>.',
      );
    }

    final isComplex = _isComplexRequest(
      prompt,
      attachment: attachment,
      attachmentType: attachmentType,
    );
    final preferredModels = isComplex
        ? _geminiModels
        : [_geminiModels[1], _geminiModels[0], ..._geminiModels.skip(2)];

    for (final modelName in preferredModels) {
      try {
        debugPrint('🤖 Trying Gemini model: $modelName');
        final response = await _tryGeminiModel(
          modelName,
          prompt,
          conversationHistory: conversationHistory,
          attachment: attachment,
          attachmentType: attachmentType,
        );
        debugPrint('✅ Gemini $modelName succeeded!');
        return response;
      } catch (e) {
        debugPrint('❌ Gemini $modelName failed: $e');
        _lastProviderError = e.toString();
        // Continue to next model
      }
    }

    // Model IDs change over time. Ask the same API key for supported models
    // before declaring the service unavailable.
    final discoveredModels = await _discoverGeminiModels();
    for (final modelName in discoveredModels) {
      if (preferredModels.contains(modelName)) continue;

      try {
        debugPrint('🤖 Trying discovered Gemini model: $modelName');
        final response = await _tryGeminiModel(
          modelName,
          prompt,
          conversationHistory: conversationHistory,
          attachment: attachment,
          attachmentType: attachmentType,
        );
        debugPrint('✅ Discovered Gemini $modelName succeeded!');
        return response;
      } catch (e) {
        debugPrint('❌ Discovered Gemini $modelName failed: $e');
        _lastProviderError = e.toString();
      }
    }

    debugPrint('❌ ALL Gemini models exhausted!');

    // 🔥 All Gemini models failed, try OpenAI as last resort
    if (_openAiApiKey.isNotEmpty) {
      try {
        debugPrint('🤖 Trying OpenAI GPT-3.5 fallback...');
        final response = await _tryOpenAi(
          prompt,
          conversationHistory: conversationHistory,
        );
        debugPrint('✅ OpenAI fallback succeeded!');
        return response;
      } catch (e) {
        debugPrint('❌ OpenAI also failed: $e');
        _lastProviderError = e.toString();
      }
    }

    // All models failed
    throw Exception(
      'All AI models unavailable. Last provider error: ${_lastProviderError.isEmpty ? 'unknown error' : _lastProviderError}',
    );
  }

  Future<List<String>> _discoverGeminiModels() async {
    if (_geminiApiKey.trim().isEmpty) return const [];

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models?key=$_geminiApiKey',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return const [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final models = data['models'] as List<dynamic>? ?? const [];
      return models
          .whereType<Map<String, dynamic>>()
          .where(
            (model) =>
                (model['supportedGenerationMethods'] as List<dynamic>? ?? [])
                    .contains('generateContent'),
          )
          .map(
            (model) =>
                (model['name'] as String? ?? '').replaceFirst('models/', ''),
          )
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('⚠️ Could not discover Gemini models: $e');
      return const [];
    }
  }

  bool _isComplexRequest(
    String prompt, {
    File? attachment,
    String? attachmentType,
  }) {
    if (attachment != null || attachmentType == 'image') return true;

    final normalized = prompt.trim().toLowerCase();
    if (normalized.length > 120 ||
        normalized.split(RegExp(r'\s+')).length > 20) {
      return true;
    }

    const complexTerms = [
      'explain',
      'details',
      'detailed',
      'step by step',
      'diagnos',
      'disease',
      'treatment',
      'fertilizer',
      'prevent',
      'compare',
      'difference',
      'why',
      'plan',
      'profitable',
      'problem',
      'not working',
    ];

    return complexTerms.any(normalized.contains);
  }

  @visibleForTesting
  String buildGeminiSystemPrompt() {
    return """You are Chinatsvi, a warm, practical, and knowledgeable farming assistant.

    Give complete, useful answers, not artificially short answers. Match the detail to the question:
    - For a simple question, give a clear answer with a brief explanation.
    - For a problem, provide likely causes, what to check, step-by-step actions, prevention, and when to seek expert help.
    - For image diagnosis, describe visible observations separately from possible causes. Do not claim certainty from an image alone.
    - For treatment advice, explain safe application, timing, dosage only when known, and relevant safety precautions.
    - Use short headings and readable bullet points when they improve clarity. Give enough detail for the farmer to act safely, usually 4-8 short paragraphs or sections.
    - Do not stop after the first idea. Cover the practical reason, exact next steps, what to monitor, and what to do if the first step does not work.
    - Be friendly and encouraging without being childish, repetitive, or overly formal.
    - Do not restate the user's question. Ask one focused follow-up question when important information is missing.
    - If a recommendation depends on crop type, growth stage, weather, soil, location, or severity, say so and explain what information would change the advice.
    - Never invent certainty, measurements, diagnoses, product names, or local regulations. Say when advice needs local expert confirmation.

    Example style:
    Start with the practical answer, then explain why it helps, give clear step-by-step actions, prevention, warning signs, and one useful follow-up question when needed. Keep simple questions reasonably concise, but for diagnosis and treatment requests provide the full explanation a farmer needs to act safely. Do not summarize away important details.""";
  }

  @visibleForTesting
  String buildOpenAiSystemPrompt() {
    return """You are Chinatsvi, a warm and practical farming assistant.

    Give a complete, useful answer rather than a short or clipped response.
    - Answer the question directly first, then add the practical reason, next steps, warnings, and one useful follow-up question if needed.
    - For diagnosis or treatment questions, provide a full explanation with likely causes, what to check, what to do next, and what to monitor.
    - Do not stop after the first paragraph or first idea. Continue until the answer is fully helpful and complete.
    - Keep the tone friendly, clear, and helpful for a farmer.
    - If important details are missing, say what information would improve the advice.
    """;
  }

  @visibleForTesting
  int getOpenAiMaxTokens() => 1200;

  @visibleForTesting
  int getGeminiMaxOutputTokens(String modelName) =>
      modelName == 'gemini-2.5-flash-lite' ? 1800 : 4096;

  /// Try a specific Gemini model with retry for 503 errors
  Future<String> _tryGeminiModel(
    String modelName,
    String prompt, {
    List<String>? conversationHistory,
    File? attachment,
    String? attachmentType,
    int attempt = 1,
  }) async {
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_geminiApiKey";

    // Build conversation context
    String conversationContext = '';
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      conversationContext = '\n\nRecent conversation context:\n';
      for (int i = 0; i < conversationHistory.length; i++) {
        conversationContext += '${conversationHistory[i]}\n';
      }
      conversationContext += '\n';
    }

    final systemPrompt = buildGeminiSystemPrompt();

    final fullPrompt = conversationContext + prompt;

    try {
      // Build the request body
      Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": systemPrompt},
              {"text": fullPrompt},
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.4,
          "maxOutputTokens": getGeminiMaxOutputTokens(modelName),
          "topP": 0.9,
          "topK": 40,
          "candidateCount": 1,
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_ONLY_HIGH",
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_ONLY_HIGH",
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_ONLY_HIGH",
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_ONLY_HIGH",
          },
        ],
      };

      // Add image attachment if provided
      if (attachment != null && attachmentType != null) {
        debugPrint('🤖 Adding image attachment to AI request');

        // Read image bytes
        final imageBytes = await attachment.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        // Determine MIME type
        final extension = attachment.path.toLowerCase().split('.').last;
        final mimeType = extension == 'png'
            ? 'image/png'
            : extension == 'webp'
            ? 'image/webp'
            : extension == 'heic' || extension == 'heif'
            ? 'image/heic'
            : 'image/jpeg';

        // Build the request body with image as a proper Map<String, dynamic>
        requestBody = {
          "contents": [
            {
              "parts": [
                {"text": systemPrompt},
                {"text": fullPrompt},
                {
                  "inline_data": {"mime_type": mimeType, "data": base64Image},
                },
              ],
            },
          ],
          "generationConfig": requestBody["generationConfig"],
          "safetySettings": requestBody["safetySettings"],
        };

        debugPrint(
          '🤖 Image added to request: ${imageBytes.length} bytes, type: $mimeType',
        );
      }

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final candidate = responseData['candidates'][0] as Map<String, dynamic>;
        final finishReason = candidate['finishReason'] ?? 'UNKNOWN';
        final parts = (candidate['content']?['parts'] as List<dynamic>? ?? []);
        final content = parts
            .whereType<Map<String, dynamic>>()
            .map((part) => part['text'])
            .whereType<String>()
            .join('\n')
            .trim();

        if (content.isEmpty) {
          throw Exception(
            'Gemini $modelName returned no text (finishReason: $finishReason)',
          );
        }

        debugPrint('🤖 Gemini finish reason: $finishReason');
        debugPrint('🤖 AI Response received: ${content.length} characters');
        return content;
      } else if (response.statusCode == 503 && attempt < 3) {
        // Retry on high demand (503)
        debugPrint(
          '⚠️ Gemini $modelName: 503 high demand, retrying in 2s... (attempt $attempt/3)',
        );
        await Future.delayed(const Duration(seconds: 2));
        return _tryGeminiModel(
          modelName,
          prompt,
          conversationHistory: conversationHistory,
          attachment: attachment,
          attachmentType: attachmentType,
          attempt: attempt + 1,
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
        final errorCode = errorData['error']?['code'] ?? response.statusCode;
        debugPrint('❌ Gemini API Error [HTTP $errorCode]: $errorMsg');
        final responsePreview = response.body.length > 500
            ? response.body.substring(0, 500)
            : response.body;
        debugPrint('❌ Full response: $responsePreview');
        throw Exception(
          'Gemini $modelName failed: HTTP $errorCode - $errorMsg',
        );
      }
    } catch (e) {
      debugPrint("❌ Gemini $modelName error: ${e.toString()}");
      rethrow; // Let fallback system handle it
    }
  }

  /// Try OpenAI GPT-3.5 as fallback
  Future<String> _tryOpenAi(
    String prompt, {
    List<String>? conversationHistory,
  }) async {
    final endpoint = "https://api.openai.com/v1/chat/completions";

    // Build messages
    final messages = <Map<String, String>>[
      {
        "role": "system",
        "content": buildOpenAiSystemPrompt(),
      },
    ];

    // Add conversation history
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      for (final msg in conversationHistory) {
        messages.add({"role": "user", "content": msg});
      }
    }

    messages.add({"role": "user", "content": prompt});

    final requestBody = {
      "model": "gpt-3.5-turbo",
      "messages": messages,
      "temperature": 0.3,
      "max_tokens": getOpenAiMaxTokens(),
    };

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAiApiKey',
          },
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final content =
          responseData['choices'][0]['message']['content'] as String;
      return content;
    } else {
      final errorData = json.decode(response.body);
      final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
      final errorCode = errorData['error']?['code'] ?? response.statusCode;
      debugPrint('❌ OpenAI API Error [HTTP $errorCode]: $errorMsg');
      final responsePreview = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;
      debugPrint('❌ OpenAI Full response: $responsePreview');
      throw Exception('OpenAI failed: HTTP $errorCode - $errorMsg');
    }
  }

  // ================= USAGE & POINTS TRACKING =================

  /// Get banked bonus points earned from rewarded ads
  Future<int> getBonusPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getEffectiveUserId();
      return prefs.getInt('$_bonusPointsKeyPrefix$userId') ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting bonus points: $e');
      return 0;
    }
  }

  /// Add rewarded ad points (banked points)
  Future<int> addRewardPoints(int points) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getEffectiveUserId();
      final currentBonus = prefs.getInt('$_bonusPointsKeyPrefix$userId') ?? 0;
      final newBonus = currentBonus + points;
      await prefs.setInt('$_bonusPointsKeyPrefix$userId', newBonus);
      debugPrint(
        '🎉 Added $points reward points. Total bonus points for $userId: $newBonus',
      );
      return newBonus;
    } catch (e) {
      debugPrint('❌ Error adding reward points: $e');
      return 0;
    }
  }

  /// Get rate limit information including daily free points and banked ad reward points
  Future<Map<String, dynamic>> getRateLimitInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getEffectiveUserId();

    debugPrint('🔍 DEBUG: getRateLimitInfo - userId: $userId');

    final todayKey = _dayKey(DateTime.now());
    final lastUsageDate =
        prefs.getString('$_lastUsageDateKeyPrefix$userId') ?? '';

    if (lastUsageDate != todayKey) {
      await prefs.setString('$_lastUsageDateKeyPrefix$userId', todayKey);
      await prefs.setInt('$_usageKeyPrefix$userId', 0);
      await prefs.setInt('$_uploadUsageKeyPrefix$userId', 0);
    }

    final currentUsage = prefs.getInt('$_usageKeyPrefix$userId') ?? 0;
    final uploadCount = prefs.getInt('$_uploadUsageKeyPrefix$userId') ?? 0;
    final bonusPoints = prefs.getInt('$_bonusPointsKeyPrefix$userId') ?? 0;

    debugPrint(
      '🔍 DEBUG: Usage - currentUsage: $currentUsage, uploadCount: $uploadCount, bonusPoints: $bonusPoints',
    );

    final verificationInfo = await _getVerificationInfo();
    final isVerified = verificationInfo['isVerified'] as bool;
    final isExpired = verificationInfo['isExpired'] as bool;
    final expiresAt = verificationInfo['expiresAt'] as DateTime?;
    final daysRemaining = verificationInfo['daysRemaining'] as int;

    debugPrint(
      '🔍 DEBUG: isVerified result: $isVerified, isExpired: $isExpired, daysRemaining: $daysRemaining',
    );

    // Use verification info we've already fetched to decide limits (avoid extra Firestore calls)
    final dailyLimit = isVerified ? _verifiedDailyLimit : _dailyLimit;
    final uploadLimit = isVerified
        ? _verifiedDailyUploadLimit
        : _dailyUploadLimit;

    debugPrint(
      '🔍 DEBUG: Limits - dailyLimit: $dailyLimit, uploadLimit: $uploadLimit',
    );

    final dailyFreeRemaining = isVerified
        ? _verifiedDailyLimit
        : (dailyLimit - currentUsage).clamp(0, dailyLimit);
    final totalRemaining = isVerified
        ? _verifiedDailyLimit
        : (dailyFreeRemaining + bonusPoints);
    final canUpload =
        isVerified ||
        (uploadCount < uploadLimit && totalRemaining >= _uploadCost);
    final unlimited = isVerified && dailyLimit >= 999999;

    debugPrint(
      '🔍 DEBUG: Final - remaining: $totalRemaining, canUpload: $canUpload, unlimited: $unlimited',
    );

    return {
      'remaining': totalRemaining,
      'dailyRemaining': dailyFreeRemaining,
      'bonusPoints': bonusPoints,
      'limit': dailyLimit,
      'unlimited': unlimited,
      'uploadCount': uploadCount,
      'uploadLimit': uploadLimit,
      'canUpload': canUpload,
      'isVerified': isVerified,
      'isExpired': isExpired,
      'expiresAt': expiresAt,
      'daysRemaining': daysRemaining,
    };
  }

  /// Track usage for rate limiting
  Future<void> trackUsage({bool isUpload = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getEffectiveUserId();

    final todayKey = _dayKey(DateTime.now());
    final lastUsageDate =
        prefs.getString('$_lastUsageDateKeyPrefix$userId') ?? '';

    if (lastUsageDate != todayKey) {
      await prefs.setString('$_lastUsageDateKeyPrefix$userId', todayKey);
      await prefs.setInt('$_usageKeyPrefix$userId', 0);
      await prefs.setInt('$_uploadUsageKeyPrefix$userId', 0);
    }

    if (isUpload) {
      final currentUploadCount =
          prefs.getInt('$_uploadUsageKeyPrefix$userId') ?? 0;
      await prefs.setInt(
        '$_uploadUsageKeyPrefix$userId',
        currentUploadCount + 1,
      );
    }

    final cost = isUpload ? _uploadCost : _textCost;
    final currentUsage = prefs.getInt('$_usageKeyPrefix$userId') ?? 0;
    final freeRemaining = (_dailyLimit - currentUsage).clamp(0, _dailyLimit);

    if (freeRemaining >= cost) {
      // Entire cost covered by daily free points
      await prefs.setInt('$_usageKeyPrefix$userId', currentUsage + cost);
    } else {
      // Use whatever free points remain, and deduct remainder from banked bonus points
      await prefs.setInt('$_usageKeyPrefix$userId', _dailyLimit);
      final neededFromBonus = cost - freeRemaining;
      final currentBonus = prefs.getInt('$_bonusPointsKeyPrefix$userId') ?? 0;
      final newBonus = (currentBonus - neededFromBonus).clamp(0, 999999);
      await prefs.setInt('$_bonusPointsKeyPrefix$userId', newBonus);
    }
  }

  /// Refund usage if request fails
  Future<void> refundUsage({bool isUpload = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getEffectiveUserId();

    final todayKey = _dayKey(DateTime.now());
    final lastUsageDate =
        prefs.getString('$_lastUsageDateKeyPrefix$userId') ?? '';

    if (lastUsageDate != todayKey) {
      await prefs.setString('$_lastUsageDateKeyPrefix$userId', todayKey);
      await prefs.setInt('$_usageKeyPrefix$userId', 0);
      await prefs.setInt('$_uploadUsageKeyPrefix$userId', 0);
      return;
    }

    if (lastUsageDate.isEmpty) return;

    if (isUpload) {
      final currentUploadCount =
          prefs.getInt('$_uploadUsageKeyPrefix$userId') ?? 0;
      if (currentUploadCount > 0) {
        await prefs.setInt(
          '$_uploadUsageKeyPrefix$userId',
          currentUploadCount - 1,
        );
      }
    }

    final cost = isUpload ? _uploadCost : _textCost;
    final currentUsage = prefs.getInt('$_usageKeyPrefix$userId') ?? 0;

    if (currentUsage >= cost) {
      await prefs.setInt('$_usageKeyPrefix$userId', currentUsage - cost);
    } else {
      // If currentUsage was partially or fully using bonus points
      final restoredFree = currentUsage;
      await prefs.setInt('$_usageKeyPrefix$userId', 0);
      final restoredBonus = cost - restoredFree;
      if (restoredBonus > 0) {
        final currentBonus = prefs.getInt('$_bonusPointsKeyPrefix$userId') ?? 0;
        await prefs.setInt(
          '$_bonusPointsKeyPrefix$userId',
          currentBonus + restoredBonus,
        );
      }
    }
  }

  /// Get comprehensive verification information including expiration details
  Future<Map<String, dynamic>> _getVerificationInfo() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        debugPrint('🔍 No user ID found, returning not verified');
        return {
          'isVerified': false,
          'isExpired': false,
          'expiresAt': null,
          'daysRemaining': 0,
        };
      }

      // Check Firestore for user verification status
      final userDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('🔍 User document not found for userId: $userId');
        return {
          'isVerified': false,
          'isExpired': false,
          'expiresAt': null,
          'daysRemaining': 0,
        };
      }

      final userData = userDoc.data() ?? {};

      // Check multiple verification fields
      final isVerified = userData['verified'] ?? false;
      final verificationStatus = userData['verificationStatus'] ?? 'none';
      final status = userData['status'] ?? 'inactive';
      final verificationPaid = userData['verificationPaid'] ?? false;

      // Check payment timestamp to see if it's expired (after 30 days from payment)
      final verificationPaidAt = userData['verificationPaidAt'] as Timestamp?;

      bool isExpired = false;
      DateTime? expiresAt;
      int daysRemaining = 0;

      if (verificationPaidAt != null && verificationPaid == true) {
        final paymentDate = verificationPaidAt.toDate();
        expiresAt = paymentDate.add(const Duration(days: 30));
        final now = DateTime.now();

        if (now.isAfter(expiresAt)) {
          isExpired = true;
          daysRemaining = 0;
        } else {
          isExpired = false;
          daysRemaining = expiresAt.difference(now).inDays;
        }
      }

      debugPrint(
        '🔍 Verification data: verified=$isVerified, verificationStatus=$verificationStatus, status=$status, verificationPaid=$verificationPaid, paidAt=$verificationPaidAt, expiresAt=$expiresAt, isExpired=$isExpired, daysRemaining=$daysRemaining',
      );

      // User is considered verified ONLY if:
      // 1. Verification status is approved AND
      // 2. Payment is still paid AND not expired
      final isCurrentlyVerified =
          (isVerified == true ||
              verificationStatus == 'approved' ||
              verificationStatus == 'verified' ||
              status == 'verified') &&
          verificationPaid == true &&
          !isExpired;

      debugPrint(
        '🔍 Final verification result: isVerified=$isCurrentlyVerified, isExpired=$isExpired',
      );

      return {
        'isVerified': isCurrentlyVerified,
        'isExpired': isExpired && verificationPaid,
        'expiresAt': expiresAt,
        'daysRemaining': daysRemaining,
      };
    } catch (e) {
      debugPrint('❌ Error checking verification status: $e');
      return {
        'isVerified': false,
        'isExpired': false,
        'expiresAt': null,
        'daysRemaining': 0,
      };
    }
  }

  /// Check if user is verified
  Future<bool> _isUserVerified() async {
    final verificationInfo = await _getVerificationInfo();
    return verificationInfo['isVerified'] as bool;
  }

  Future<String> _getEffectiveUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseUserId = FirebaseAuth.instance.currentUser?.uid;

      if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
        await prefs.setString('current_user_id', firebaseUserId);
        await _clearLegacySharedQuotaKeys();
        return firebaseUserId;
      }

      final storedUserId = prefs.getString('current_user_id');
      if (storedUserId != null && storedUserId.isNotEmpty) {
        return storedUserId;
      }

      var anonymousUserId = prefs.getString(_anonymousUserIdKey);
      if (anonymousUserId == null || anonymousUserId.isEmpty) {
        anonymousUserId = const Uuid().v4();
        await prefs.setString(_anonymousUserIdKey, anonymousUserId);
      }

      return anonymousUserId;
    } catch (e) {
      debugPrint('❌ Error resolving AI user ID: $e');
      return 'anonymous_ai_user';
    }
  }

  Future<void> _clearLegacySharedQuotaKeys() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'ai_daily_usage_current_user',
      'ai_last_usage_date_current_user',
      'ai_daily_upload_current_user',
    ]) {
      await prefs.remove(key);
    }
  }

  /// Get current user ID
  Future<String?> _getCurrentUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.uid;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      return userId;
    } catch (e) {
      debugPrint('❌ Error getting current user ID: $e');
      return null;
    }
  }

  void clearCache() {
    debugPrint('AI response cache cleared');
  }
}
