import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/routes/route_generator.dart';
import 'services/ad_manager.dart';

import 'app/routes/app_routes.dart';
import 'firebase_options.dart';
import 'screens/auth/app_initializer.dart';
import 'app/utils/formatters.dart';
import 'services/cache/profile_cache_service.dart';
import 'services/cache/post_cache_service.dart';
import 'services/cache/feed_cache_service.dart';
import 'services/cache/sync_service.dart';
import 'services/marketplace_boost_service.dart';
import 'services/profile_picture_preloader.dart';
import 'controllers/feed_controller.dart';
// import 'providers/clean_providers.dart'; // Use clean providers

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🔔 Top-level background message handler for Firebase Cloud Messaging
/// Runs in a separate Dart background isolate when app is closed/terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final data = message.data;
    if (data['type'] == 'chat_message') {
      final chatId = data['chatId']?.toString();
      final messageId = data['messageId']?.toString();

      if (chatId != null && messageId != null) {
        // 🔥 Immediately acknowledge delivery in Firestore so sender gets double tick (✓✓)
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({
          'status': 'delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
        });
      }

      // Show local heads-up notification in background
      final title = message.notification?.title ?? data['senderName']?.toString() ?? 'New Message';
      final body = message.notification?.body ?? data['body']?.toString() ?? 'Sent you a message';

      final FlutterLocalNotificationsPlugin localNotifs = FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'agribased_chat_channel',
        'AgriBase Chat Messages',
        channelDescription: 'Notifications for incoming chat messages',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
      final id = (chatId ?? '').hashCode.abs() % 100000;
      await localNotifs.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: 'chat:$chatId',
      );
    }
  } catch (e) {
    debugPrint('⚠️ Error in background message handler: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🌱 ENV - Load environment variables first (fast)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }

    // 🚀 Fast parallel startup: Hive + Caches + Firebase + Formatter together
    await Future.wait([
      () async {
        await Hive.initFlutter();
        await Hive.openBox('feed_cache');
        await Hive.openBox('feed_posts');
        await Hive.openBox('guidebook_unlocks');
        await Future.wait([
          ProfileCacheService.init(),
          PostCacheService.init(),
          FeedCacheService.init(),
          ProfilePicturePreloader().init(),
        ]);
        debugPrint('🔥 Hive & Cache services initialized');
      }(),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      Formatter.init(),
    ]);
    debugPrint('🔥 Core startup services initialized in parallel');

    // 🔔 Register background FCM message handler
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('⚠️ onBackgroundMessage registration failed: $e');
    }

    // ⚡ Non-critical background tasks (do not block UI first frame)
    _startBackgroundServices();

    // 📱 Initialize Google Mobile Ads AFTER first frame paints
    _initMobileAdsInBackground();

    // ✅ Show app immediately — AppInitializer handles screen routing seamlessly
    runApp(const ProviderScope(child: SplashApp()));
  } on FirebaseException catch (e) {
    debugPrint('🔥 Firebase initialization failed: $e');
    runApp(const FirebaseErrorApp());
  } catch (e) {
    debugPrint('App initialization failed: $e');
    runApp(const ErrorApp());
  }
}

/// Run non-critical startup tasks in the background without blocking the UI
void _startBackgroundServices() {
  // Sync service & offline support
  try {
    SyncService();
  } catch (e) {
    debugPrint('⚠️ SyncService background init failed: $e');
  }

  // Pre-warm feed controller
  try {
    FeedController();
  } catch (e) {
    debugPrint('⚠️ FeedController background init failed: $e');
  }

  // Firestore offline persistence
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('⚠️ Firestore offline settings failed: $e');
  }

  // Marketplace boost cleanup
  try {
    MarketplaceBoostService.instance.startBoostListener(enabled: false);
    MarketplaceBoostService.instance.cleanupExpiredBoosts();
  } catch (e) {
    debugPrint('⚠️ Marketplace boost background init failed: $e');
  }
}

/// Initialize Google Mobile Ads after the UI paints its first frame
void _initMobileAdsInBackground() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdManager.instance.initialize();
  });
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Farmers Community',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white, // Professional white background
      ),
      // 🔥 SINGLE ENTRY POINT - Only AppInitializer decides routing
      home: const AppInitializer(),
      onGenerateRoute: RouteGenerator.generateRoute,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('sn', ''),
        Locale('zu', ''),
        Locale('af', ''),
      ],
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmers Community - Error',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please check your internet connection and restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmers Community',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        backgroundColor: Colors.orange.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 80, color: Colors.orange.shade700),
                const SizedBox(height: 24),
                const Text(
                  'Connection Required',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to connect to services. Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.appInitializer);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
