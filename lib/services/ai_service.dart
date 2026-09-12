import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../utils/verification_helpers.dart';

class AiService {
  static AiService? _instance;
  static AiService get instance => _instance ??= AiService._();

  AiService._();

  String _apiKey = '';

  // Usage tracking - now per user
  static const String _usageKeyPrefix = 'ai_daily_usage_';
  static const String _lastUsageDateKeyPrefix = 'ai_last_usage_date_';
  static const String _anonymousUserIdKey = 'ai_anonymous_user_id';
  static const int _dailyLimit = 25; // 25 requests per day per user

  /// Get user-specific usage keys
  String _getUsageKey(String userId) => '${_usageKeyPrefix}$userId';
  String _getLastUsageDateKey(String userId) =>
      '${_lastUsageDateKeyPrefix}$userId';

  Future<String> _getEffectiveUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
      debugPrint('Error resolving AI user ID: $e');
      return 'anonymous_ai_user';
    }
  }

  /// Get current user ID
  Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_user_id');
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  /// Check if user has reached daily limit (verified users have unlimited requests)
  Future<bool> _hasReachedDailyLimit() async {
    try {
      final userId = await _getEffectiveUserId();

      // Check if user is verified
      final isVerified = await _isUserVerified(userId);
      if (isVerified) {
        debugPrint('User $userId is verified - unlimited requests');
        return false; // Verified users have unlimited requests
      }

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD
      final lastUsageDate = prefs.getString(_getLastUsageDateKey(userId)) ?? '';
      final currentUsage = prefs.getInt(_getUsageKey(userId)) ?? 0;

      // Reset counter if it's a new day
      if (lastUsageDate != today) {
        await prefs.setString(_getLastUsageDateKey(userId), today);
        await prefs.setInt(_getUsageKey(userId), 0);
        return false;
      }

      return currentUsage >= _dailyLimit;
    } catch (e) {
      debugPrint('Error checking usage limit: $e');
      return false; // Allow usage if we can't track
    }
  }

  /// Check if user is verified (has green tick) - real-time check with cache integration
  Future<bool> _isUserVerified(String userId) async {
    try {
      // Always fetch fresh data from Firestore to avoid stale cache issues
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();

      if (!doc.exists) {
        debugPrint('User document not found for $userId');
        return false;
      }

      final data = doc.data();
      final isVerified = _calculateVerificationStatus(data);

      debugPrint('User $userId verification status: $isVerified');

      return isVerified;
    } catch (e) {
      debugPrint('Error checking verification status: $e');
      return false;
    }
  }

  /// Calculate verification status based on user data (matches VerificationCacheService logic)
  bool _calculateVerificationStatus(Map<String, dynamic>? userData) {
    if (userData == null || userData.isEmpty) return false;

    final verificationStatus = userData['verificationStatus'] as String?;
    final isPaid = userData['verificationPaid'] as bool? ?? false;
    final expiryDate = resolveVerificationExpiryDate(userData);

    if (expiryDate != null && !DateTime.now().isBefore(expiryDate)) {
      debugPrint('Verification expired on $expiryDate');
      return false;
    }

    final isActive =
        verificationStatus != null &&
        verificationStatus.isNotEmpty &&
        isPaid &&
        (expiryDate == null || DateTime.now().isBefore(expiryDate));

    return isActive;
  }

  /// Increment usage counter for current user
  Future<void> _incrementUsage({int requestsConsumed = 1}) async {
    try {
      final userId = await _getEffectiveUserId();

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastUsageDate = prefs.getString(_getLastUsageDateKey(userId)) ?? '';
      final currentUsage = prefs.getInt(_getUsageKey(userId)) ?? 0;

      // Reset if new day
      if (lastUsageDate != today) {
        await prefs.setString(_getLastUsageDateKey(userId), today);
        await prefs.setInt(_getUsageKey(userId), requestsConsumed);
      } else {
        await prefs.setInt(
          _getUsageKey(userId),
          currentUsage + requestsConsumed,
        );
      }

      debugPrint(
        'User $userId usage: ${currentUsage + requestsConsumed}/$_dailyLimit (consumed $requestsConsumed requests)',
      );
    } catch (e) {
      debugPrint('Error incrementing usage: $e');
    }
  }

  /// Check if user has enough requests for media upload (5 requests required, verified users have unlimited)
  Future<bool> hasEnoughRequestsForMedia() async {
    final userId = await _getEffectiveUserId();

    // Verified users always have enough requests
    final isVerified = await _isUserVerified(userId);
    if (isVerified) {
      return true;
    }

    final remaining = await getRemainingRequests();
    return remaining >= 5;
  }

  /// Get remaining daily requests for current user (verified users have unlimited)
  Future<int> getRemainingRequests() async {
    try {
      final userId = await _getEffectiveUserId();

      // Check if user is verified
      final isVerified = await _isUserVerified(userId);
      if (isVerified) {
        return 999999; // Return a high number to represent "unlimited"
      }

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastUsageDate = prefs.getString(_getLastUsageDateKey(userId)) ?? '';
      final currentUsage = prefs.getInt(_getUsageKey(userId)) ?? 0;

      if (lastUsageDate != today) {
        return _dailyLimit;
      }

      return (_dailyLimit - currentUsage).clamp(0, _dailyLimit);
    } catch (e) {
      return _dailyLimit;
    }
  }

  /// Initializes AI service with your Gemini API key.
  void initialize(String key) {
    _apiKey = key;
  }

  /// Set current user ID (call this when user logs in)
  Future<void> setCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      debugPrint('Set current user ID for AI usage tracking: $userId');
    } catch (e) {
      debugPrint('Error setting current user ID: $e');
    }
  }

  /// Force refresh verification status (call when payment status changes)
  Future<void> refreshVerificationStatus() async {
    final userId = await _getCurrentUserId();
    if (userId != null) {
      debugPrint('Refreshing verification status for user $userId');
      // This will trigger a fresh check on next AI request
    }
  }

  /// Get current verification status (for UI updates)
  Future<bool> getCurrentVerificationStatus() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;
    return await _isUserVerified(userId);
  }

  /// Clear current user ID (call this when user logs out)
  Future<void> clearCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      debugPrint('Cleared current user ID for AI usage tracking');
    } catch (e) {
      debugPrint('Error clearing current user ID: $e');
    }
  }

  /// Check if prompt contains harmful content
  bool _isHarmfulContent(String prompt) {
    final harmfulPatterns = [
      // Violence and illegal activities
      RegExp(
        r'\b(kill|murder|harm|hurt|violence|weapon|bomb|terror|illegal)\b',
        caseSensitive: false,
      ),
      RegExp(r'\b(drug|overdose|suicide|self.harm)\b', caseSensitive: false),

      // Hate speech
      RegExp(
        r'\b(hate|racist|nazi|discriminat|sexist)\b',
        caseSensitive: false,
      ),

      // Adult content
      RegExp(r'\b(porn|nude|sexual|explicit)\b', caseSensitive: false),

      // Dangerous activities
      RegExp(r'\b(hack|crack|malware|virus|phishing)\b', caseSensitive: false),

      // Financial fraud
      RegExp(
        r'\b(scam|fraud|money.laundering|counterfeit)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in harmfulPatterns) {
      if (pattern.hasMatch(prompt)) {
        return true;
      }
    }
    return false;
  }

  /// Sends a prompt to Gemini with image/file analysis (consumes 5 requests)
  Future<String> getResponseWithMedia(
    String prompt, {
    bool hasMedia = false,
  }) async {
    if (_apiKey.isEmpty) {
      return 'Error: Gemini API key is missing';
    }

    // Check daily usage limit
    if (await _hasReachedDailyLimit()) {
      final userId = await _getCurrentUserId();
      final isVerified = userId != null ? await _isUserVerified(userId) : false;
      if (isVerified) {
        return '✅ Verified users have unlimited AI requests! Ask anything you need help with.';
      }
      return '⏰ Daily limit reached. You can ask ${_dailyLimit} questions per day. Try again tomorrow!';
    }

    // Check for harmful content
    if (_isHarmfulContent(prompt)) {
      return '🚫 I cannot respond to this request as it may involve harmful, illegal, or inappropriate content. Please ask a different question.';
    }

    const endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

    debugPrint('Using endpoint: $endpoint');
    debugPrint('API Key: ${_apiKey.isNotEmpty ? 'Present' : 'Missing'}');
    debugPrint('Has media: $hasMedia');

    // Retry logic for 503 errors
    int attempts = 0;
    const maxAttempts = 4;

    while (attempts < maxAttempts) {
      try {
        // Show friendly message on retry attempts
        if (attempts > 0) {
          debugPrint('Retry attempt ${attempts + 1}/$maxAttempts');
        }

        final response = await http.post(
          Uri.parse('$endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        '''You are Chinatsvi, an AI assistant for farming. Answer directly and concisely in 1-2 short sentences unless the user asks for more.

If an image is provided, analyze the image and give 2-3 concise actionable points. Do not add preamble, do not repeat the question, and do not add closing remarks.

User question: $prompt''',
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': hasMedia ? 0.35 : 0.2,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': hasMedia ? 400 : 200,
            },
            'safetySettings': [
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_HATE_SPEECH',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
            ],
          }),
        );

        // Increment usage after making the request (5 for media, 1 for text)
        await _incrementUsage(requestsConsumed: hasMedia ? 5 : 1);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (content != null && content is String) {
            return content.trim();
          } else {
            return 'Error: Gemini response was empty or malformed.';
          }
        } else if (response.statusCode == 503) {
          // Handle 503 Service Unavailable error
          attempts++;
          if (attempts < maxAttempts) {
            debugPrint('503 error, waiting 2 seconds before retry...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          } else {
            // After 4 attempts, show friendly message
            return 'Server busy, please try again later.';
          }
        } else {
          // Handle other HTTP errors
          debugPrint('API Error: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['error']?['message'] ?? 'Unknown error';
          return 'Error: ${response.statusCode} - $errorMessage';
        }
      } catch (e) {
        debugPrint('Gemini AI Service Error: $e');
        debugPrint('Error type: ${e.runtimeType}');

        // Check if it's a 503-related exception
        if (e.toString().contains('503') ||
            e.toString().contains('Service Unavailable')) {
          attempts++;
          if (attempts < maxAttempts) {
            debugPrint('503-related error, waiting 2 seconds before retry...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          } else {
            return 'Server busy, please try again later.';
          }
        }

        if (e is FormatException) {
          debugPrint(
            'JSON parsing error - response body might be empty or invalid',
          );
          debugPrint(
            'This usually means the API endpoint is wrong or the API key is invalid',
          );
        }
        return 'Error: Failed to get Gemini AI response.';
      }
    }

    // This should not be reached, but just in case
    return 'Server busy, please try again later.';
  }

  /// Sends a prompt to Gemini and returns the response with retry logic for 503 errors (consumes 1 request)
  Future<String> getResponse(String prompt) async {
    return await getResponseWithMedia(prompt, hasMedia: false);
  }

  /// Get farming advice from AI
  Future<String> getFarmingAdvice(String topic, String context) async {
    final prompt =
        '''
As an expert agricultural advisor, provide detailed advice about: $topic

Context: $context

Please provide:
1. Practical steps
2. Best practices
3. Common mistakes to avoid
4. Seasonal considerations if relevant

Keep the response concise but comprehensive and farmer-friendly.
''';

    return await getResponse(prompt);
  }

  /// Analyze crop disease symptoms
  Future<String> analyzeCropDisease(String symptoms, String cropType) async {
    final prompt =
        '''
As an agricultural expert, analyze these crop disease symptoms for $cropType:

Symptoms: $symptoms

Please provide:
1. Possible diseases/conditions
2. Recommended treatments
3. Prevention measures
4. When to seek professional help

Note: This is not a substitute for professional agricultural extension services.
''';

    return await getResponse(prompt);
  }

  /// Get market price predictions
  Future<String> getMarketPricePrediction(String crop, String region) async {
    final prompt =
        '''
As an agricultural market analyst, provide price prediction insights for $crop in $region:

Please analyze:
1. Current market trends
2. Seasonal price patterns
3. Factors affecting prices
4. Best time to sell
5. Price range expectations

Note: This is for informational purposes only. Actual prices may vary.
''';

    return await getResponse(prompt);
  }

  /// Get soil improvement recommendations
  Future<String> getSoilRecommendations(
    String soilType,
    String plannedCrop,
  ) async {
    final prompt =
        '''
As a soil science expert, provide recommendations for improving $soilType soil for growing $plannedCrop:

Please provide:
1. Soil analysis interpretation
2. Nutrient recommendations
3. Organic matter improvement
4. pH adjustment if needed
5. Long-term soil health strategies

Focus on sustainable and organic methods where possible.
''';

    return await getResponse(prompt);
  }

  /// Get pest control advice
  Future<String> getPestControlAdvice(String pestType, String crop) async {
    final prompt =
        '''
As an integrated pest management expert, provide advice for controlling $pestType in $crop:

Please provide:
1. Pest identification confirmation
2. Life cycle understanding
3. Cultural control methods
4. Biological control options
5. Organic pesticide options
6. Chemical options as last resort
7. Prevention strategies

Prioritize environmentally friendly and sustainable methods.
''';

    return await getResponse(prompt);
  }

  /// Get irrigation recommendations
  Future<String> getIrrigationAdvice(
    String crop,
    String soilType,
    String climate,
  ) async {
    final prompt =
        '''
As an irrigation specialist, provide watering advice for $crop in $soilType soil under $climate conditions:

Please provide:
1. Watering frequency
2. Water amount guidelines
3. Best irrigation methods
4. Drought management
5. Water conservation techniques
6. Signs of over/under watering

Focus on water efficiency and crop health.
''';

    return await getResponse(prompt);
  }

  /// Get harvest timing advice
  Future<String> getHarvestTimingAdvice(
    String crop,
    String plantingDate,
  ) async {
    final prompt =
        '''
As an agricultural expert, provide harvest timing advice for $crop planted on $plantingDate:

Please provide:
1. Expected harvest window
2. Signs of readiness
3. Harvesting techniques
4. Post-harvest handling
5. Storage recommendations
6. Market timing considerations

Consider typical maturity periods and visual indicators.
''';

    return await getResponse(prompt);
  }

  /// Get crop rotation suggestions
  Future<String> getCropRotationSuggestions(
    String currentCrop,
    String nextSeasonCrop,
  ) async {
    final prompt =
        '''
As a sustainable agriculture expert, provide crop rotation advice for transitioning from $currentCrop to $nextSeasonCrop:

Please provide:
1. Rotation benefits
2. Soil preparation needs
3. Nutrient considerations
4. Disease break benefits
5. Multi-year rotation plan
6. Cover crop recommendations

Focus on soil health and pest management benefits.
''';

    return await getResponse(prompt);
  }

  /// Get fertilizer recommendations
  Future<String> getFertilizerRecommendations(
    String crop,
    String soilType,
    String growthStage,
  ) async {
    final prompt =
        '''
As a soil fertility expert, provide fertilizer recommendations for $crop in $soilType soil at $growthStage stage:

Please provide:
1. N-P-K requirements
2. Organic fertilizer options
3. Application timing
4. Application methods
5. Soil testing recommendations
6. Environmental considerations

Prioritize balanced nutrition and environmental stewardship.
''';

    return await getResponse(prompt);
  }

  /// Get weather impact analysis
  Future<String> getWeatherImpactAnalysis(
    String currentWeather,
    String forecast,
    String cropStage,
  ) async {
    final prompt =
        '''
As an agronomist, analyze the impact of current and forecast weather on crops at $cropStage stage:

Current Weather: $currentWeather
Forecast: $forecast

Please analyze:
1. Immediate impacts
2. Risk assessment
3. Protective measures needed
4. Opportunities presented
5. Monitoring recommendations
6. Contingency planning

Focus on practical, actionable advice.
''';

    return await getResponse(prompt);
  }

  /// Get general farming tips
  Future<String> getFarmingTips(String category) async {
    final prompt =
        '''
As an experienced farming mentor, provide practical tips for $category:

Please provide:
1. Quick wins
2. Common mistakes
3. Best practices
4. Time-saving techniques
5. Cost-effective solutions
6. Expert insights

Make it practical and easy to implement.
''';

    return await getResponse(prompt);
  }
}
