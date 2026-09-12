import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/user_profile.dart'; // <- Updated import
import 'firebase_service.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  AnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final FirebaseAnalytics _analytics = FirebaseService.instance.analytics;
  final FirebaseCrashlytics _crashlytics = FirebaseService.instance.crashlytics;

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      if (parameters != null && parameters.isNotEmpty) {
        final Map<String, String> sanitizedParams = {};
        parameters.forEach((key, dynamic value) {
          if (value != null) sanitizedParams[key] = value.toString();
        });
        await _analytics.logEvent(name: name, parameters: sanitizedParams);
      } else {
        await _analytics.logEvent(name: name);
      }
      debugPrint('Event logged: $name');
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('Screen view logged: $screenName');
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  Future<void> logUserLogin(String method) async =>
      await logEvent('login', parameters: {'method': method});

  Future<void> logUserSignUp(String method) async =>
      await logEvent('sign_up', parameters: {'method': method});

  Future<void> logPostCreated(String postId, {String? contentType}) async =>
      await logEvent('post_created', parameters: {'post_id': postId, 'content_type': contentType ?? 'text'});

  Future<void> logPostShared(String postId, String platform) async =>
      await logEvent('post_shared', parameters: {'post_id': postId, 'platform': platform});

  Future<void> logPostReaction(String postId, String reactionType) async =>
      await logEvent('post_reaction', parameters: {'post_id': postId, 'reaction_type': reactionType});

  Future<void> logCommentAdded(String postId) async =>
      await logEvent('comment_added', parameters: {'post_id': postId});

  Future<void> logFollow(String followedUserId) async =>
      await logEvent('follow', parameters: {'followed_user_id': followedUserId});

  Future<void> logUnfollow(String unfollowedUserId) async =>
      await logEvent('unfollow', parameters: {'unfollowed_user_id': unfollowedUserId});

  Future<void> logChatMessageSent(String chatId, {String? messageType}) async =>
      await logEvent('chat_message_sent', parameters: {'chat_id': chatId, 'message_type': messageType ?? 'text'});

  Future<void> logMediaUpload(String mediaType, {int? fileSize}) async =>
      await logEvent('media_upload', parameters: {'media_type': mediaType, if (fileSize != null) 'file_size': fileSize});

  Future<void> logProfileUpdate(String updatedField) async =>
      await logEvent('profile_update', parameters: {'updated_field': updatedField});

  Future<void> logSearch(String searchTerm, {String? searchType}) async =>
      await logEvent('search', parameters: {'search_term': searchTerm, 'search_type': searchType ?? 'general'});

  Future<void> logError(Exception error, StackTrace stackTrace, {String? context}) async {
    try {
      await _crashlytics.recordError(error, stackTrace, reason: context);
      debugPrint('Error logged to Crashlytics: $error');
    } catch (e) {
      debugPrint('Error logging to Crashlytics: $e');
    }
  }

  Future<void> logMessage(String message) async {
    try {
      _crashlytics.log(message);
      debugPrint('Message logged to Crashlytics: $message');
    } catch (e) {
      debugPrint('Error logging message to Crashlytics: $e');
    }
  }

  // ---------------- SAFE USER PROPERTIES ----------------
  Future<void> setUserProperties(UserProfile user) async {
    try {
      final String role = (user.badgeLevel ?? '').toString();
      final String? address = user.location;

      if (role.isNotEmpty) {
        await _analytics.setUserProperty(name: 'account_type', value: role);
      }
      if (address != null && address.isNotEmpty) {
        await _analytics.setUserProperty(name: 'location', value: address);
      }

      debugPrint('User properties set for analytics');
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('User ID set for analytics: $userId');
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  Future<void> trackPostAnalytics(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final postData = postDoc.data()!;
      final analytics = PostAnalytics.fromJson(postData['analytics'] ?? {});

      await logEvent('post_analytics_tracked', parameters: {
        'post_id': postId,
        'views': analytics.viewsCount,
        'likes': analytics.reactionsCount,
        'comments': analytics.commentsCount,
        'shares': analytics.sharesCount,
        'reach_score': analytics.viewsCount,
      });
    } catch (e) {
      debugPrint('Error tracking post analytics: $e');
    }
  }

  Future<void> trackUserEngagement(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final followersCount = userData['followersCount'] ?? 0;
      final followingCount = userData['followingCount'] ?? 0;
      final postsCount = userData['postsCount'] ?? 0;

      await logEvent('user_engagement_tracked', parameters: {
        'user_id': userId,
        'followers_count': followersCount,
        'following_count': followingCount,
        'posts_count': postsCount,
      });
    } catch (e) {
      debugPrint('Error tracking user engagement: $e');
    }
  }

  Future<void> trackAppSession() async => await logEvent('app_session_started');

  Future<void> trackFeatureUsage(String featureName, {Map<String, dynamic>? parameters}) async {
    final params = parameters ?? {};
    params['feature_name'] = featureName;
    await logEvent('feature_used', parameters: params);
  }

  Future<void> trackPerformanceMetric(String metricName, double value, {String? unit}) async {
    final params = <String, Object?>{
      'metric_name': metricName,
      'value': value,
      if (unit != null) 'unit': unit,
    };
    await logEvent('performance_metric', parameters: params);
  }

  Future<void> trackCustomEvent(String eventName, {Map<String, Object?>? parameters}) async =>
      await logEvent(eventName, parameters: parameters);
}
