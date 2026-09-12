import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../services/build_config_service.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/secure_auth_service.dart';
import '../../services/cache/profile_cache_service.dart';
import '../../services/cache/connectivity_service.dart';

/// Helper for the minimal cold-start floor.
Duration getStartupFloorDuration({
  required String? storedUserId,
  required bool hasCachedProfile,
  required bool hasAuthenticatedUser,
}) {
  if (storedUserId != null && hasCachedProfile) return Duration.zero;
  if (hasAuthenticatedUser) return Duration.zero;
  return const Duration(milliseconds: 250);
}

/// 🔥 PRODUCTION SINGLE ENTRY POINT
/// ONLY this class decides where user goes
/// No other screen decides navigation - they are just destinations
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  String _statusMessage = '';
  final SecureAuthService _secureAuth = SecureAuthService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isAuthenticated = false;
  bool _hasShownOfflineMessage = false;

  @override
  void initState() {
    super.initState();
    _start();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Listen for connectivity changes and auto-retry login when internet comes back
  void _setupConnectivityListener() {
    final connectivityService = ConnectivityService();
    connectivityService.startListening();

    _connectivitySubscription = connectivityService.connectivityStream.listen((
      isOnline,
    ) {
      print(
        '🌐 [CONNECTIVITY] Status changed: ${isOnline ? "ONLINE" : "OFFLINE"}',
      );

      if (isOnline && !_isAuthenticated) {
        // Internet is back but we're not authenticated - try to restore in background
        print(
          '🔄 [CONNECTIVITY] Internet restored, attempting background login...',
        );
        _attemptBackgroundLogin();
      }
    });
  }

  /// Attempt to restore authentication silently in the background
  Future<void> _attemptBackgroundLogin() async {
    try {
      // Wait a moment for network to stabilize
      await Future.delayed(const Duration(seconds: 1));

      // Check if user is already authenticated now
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print(
          '✅ [CONNECTIVITY] User already authenticated: ${currentUser.uid}',
        );
        _isAuthenticated = true;
        return;
      }

      // Try to restore from secure storage
      final userId = await _secureAuth.getStoredUserId();
      if (userId == null) {
        print('⚠️ [CONNECTIVITY] No stored userId to restore');
        return;
      }

      print('🔄 [CONNECTIVITY] Attempting auto-login for user: $userId');
      final user = await _secureAuth.autoLogin();

      if (user != null) {
        print('✅ [CONNECTIVITY] Background login SUCCESS: ${user.uid}');
        _isAuthenticated = true;

        // If we're still on the initializer screen, proceed with user
        if (mounted && !_hasShownOfflineMessage) {
          await _proceedWithUser(user.uid);
        }
      } else {
        print('❌ [CONNECTIVITY] Background login failed');
      }
    } catch (e) {
      print('❌ [CONNECTIVITY] Error during background login: $e');
    }
  }

  /// 🔥 OFFLINE-SAFE: Cached data first, Firebase second, welcome last
  Future<void> _start() async {
    print('========================================');
    print('🔥 [APP_INIT] STARTING APP INITIALIZER');
    print('========================================');
    final startTime = DateTime.now();

    _initServices();

    String? storedUserId;
    bool hasCachedProfile = false;

    // STEP 0: Fast local check — no Firebase/network wait at all.
    try {
      storedUserId = await _secureAuth.getStoredUserId().timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );

      if (storedUserId != null) {
        final cachedProfile = ProfileCacheService.getCachedProfile(
          storedUserId,
        );
        hasCachedProfile = cachedProfile != null;

        if (hasCachedProfile) {
          print(
            '🚀 [STEP 0] Cached profile found for $storedUserId — instant nav',
          );
          _hasShownOfflineMessage = FirebaseAuth.instance.currentUser == null;
          _go(AppRoutes.community);
          unawaited(_reconcileAuthInBackground(storedUserId));
          return;
        }
      }
    } catch (e) {
      print('⚠️ [STEP 0] Cached profile check failed: $e');
    }

    // STEP 1: Check currentUser immediately
    var user = FirebaseAuth.instance.currentUser;
    print('🔥 [STEP 1] currentUser immediate check: ${user?.uid ?? "NULL"}');

    if (user != null) {
      print('✅ [STEP 1] User found immediately - going to Community');
      await _proceedWithUser(user.uid);
      return;
    }
    print('⚠️ [STEP 1] currentUser is NULL, proceeding to wait...');

    // STEP 2: Wait for Firebase to restore (max 1.5 seconds)
    print('⏳ [STEP 2] Waiting for Firebase authStateChanges (1.5s max)...');
    user = await _waitForFirebase();

    if (user != null) {
      print('✅ [STEP 2] Firebase restored user: ${user.uid}');
      await _proceedWithUser(user.uid);
      return;
    }
    print('❌ [STEP 2] Firebase returned NULL after 1.5s wait');

    // STEP 3: Firebase failed, try secure storage
    print('📦 [STEP 3] Trying secure storage fallback...');
    setState(() => _statusMessage = 'Restoring session...');
    user = await _trySecureStorage();

    if (!mounted) return;
    if (user != null) {
      print('✅ [STEP 3] Secure storage restored user: ${user.uid}');
      await _proceedWithUser(user.uid);
      return;
    }
    print('❌ [STEP 3] Secure storage also failed');

    final floor = getStartupFloorDuration(
      storedUserId: storedUserId,
      hasCachedProfile: hasCachedProfile,
      hasAuthenticatedUser: false,
    );
    await _ensureMinLoadingTime(startTime, floorMs: floor.inMilliseconds);

    print('🚪 [FINAL] Navigating to WELCOME screen');
    _go(AppRoutes.welcome);
  }

  /// Reconcile the real Firebase auth silently in the background after a cached-profile nav.
  Future<void> _reconcileAuthInBackground(String storedUserId) async {
    try {
      final user = await _waitForFirebase();
      if (user != null) {
        _isAuthenticated = true;
        await _secureAuth.saveAuthCredentials(user);
        print('✅ [RECONCILE] Background auth confirmed: ${user.uid}');
        return;
      }

      final restoredUser = await _trySecureStorage();
      if (restoredUser != null) {
        _isAuthenticated = true;
        print('✅ [RECONCILE] Background secure-storage login confirmed');
      } else {
        print(
          '⚠️ [RECONCILE] Could not confirm auth — user stays on cached view',
        );
      }
    } catch (e) {
      print('⚠️ [RECONCILE] Error: $e');
    }
  }

  /// Wait for Firebase auth with 1.5 second timeout
  Future<User?> _waitForFirebase() async {
    final completer = Completer<User?>();
    StreamSubscription<User?>? sub;

    final timer = Timer(const Duration(milliseconds: 1500), () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(null);
    });

    sub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (u != null && !completer.isCompleted) {
        timer.cancel();
        completer.complete(u);
        sub?.cancel();
      }
    });

    return completer.future;
  }

  /// Try to restore from secure storage with 2 second timeout
  Future<User?> _trySecureStorage() async {
    print('📦 [SECURE] Checking secure storage for credentials...');
    try {
      final creds = await _secureAuth.getStoredLoginCredentials().timeout(
        const Duration(seconds: 2),
      );

      if (creds != null) {
        // 🔥 Double-check password is not empty
        if (creds['password'] == null || creds['password']!.isEmpty) {
          print('❌ [SECURE] Password is EMPTY - corrupted data');
          print('🧹 [SECURE] Clearing corrupted credentials...');
          await _secureAuth.clearAuthData();
          return null;
        }
        print('📦 [SECURE] Found credentials for: ${creds['email']}');
        print('🔄 [SECURE] Attempting auto-login...');
        final user = await _secureAuth.autoLogin();
        if (user != null) {
          print('✅ [SECURE] Auto-login SUCCESS: ${user.uid}');
        } else {
          print('❌ [SECURE] Auto-login FAILED - wrong password?');
        }
        return user;
      } else {
        print('❌ [SECURE] No stored credentials found');
      }
    } on PlatformException catch (e) {
      // BAD_DECRYPT error - encryption key lost (reinstall, debug→release, etc)
      print('⚠️ [SECURE] Decryption failed (key lost): ${e.message}');
      print('🧹 [SECURE] Clearing corrupted storage...');
      await _secureAuth.clearAuthData();
      print('✅ [SECURE] Storage cleared - user must login once');
    } catch (e) {
      print('⚠️ [SECURE] Error accessing secure storage: $e');
    }
    return null;
  }

  /// Ensure a short minimum loading time to prevent UI flash on true cold starts.
  Future<void> _ensureMinLoadingTime(
    DateTime start, {
    int floorMs = 250,
  }) async {
    if (floorMs <= 0) return;

    final elapsed = DateTime.now().difference(start);
    final floor = Duration(milliseconds: floorMs);
    if (elapsed < floor) {
      await Future.delayed(floor - elapsed);
    }
  }

  /// Proceed with authenticated user
  Future<void> _proceedWithUser(String uid) async {
    if (!mounted) return;
    _isAuthenticated = true;

    // Save fresh credentials in background
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _secureAuth.saveAuthCredentials(currentUser);
    }

    // Try to load cached profile first (for offline support like WhatsApp)
    final cachedProfile = ProfileCacheService.getCachedProfile(uid);
    if (cachedProfile != null) {
      print('✅ [CACHE] Found cached profile for user $uid');
      print('🚀 [CACHE] Proceeding with cached data (offline mode possible)');
      _go(AppRoutes.community);
      return;
    }

    print('⚠️ [CACHE] No cached profile found, fetching from Firestore...');

    // Check profile exists
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      if (doc.exists) {
        // Cache the profile for offline use
        await ProfileCacheService.cacheProfile(uid, doc.data()!);
        print('✅ [APP_INIT] Profile cached → Community');
        _go(AppRoutes.community);
      } else {
        print('⚠️ [APP_INIT] No profile → Welcome');
        _go(AppRoutes.welcome);
      }
    } catch (e) {
      print('⚠️ [APP_INIT] Firestore error → Community');
      if (mounted) _go(AppRoutes.community);
    }
  }

  /// Navigate to route
  void _go(String route) {
    if (!mounted) return;
    print('🧭 [APP_INIT] Navigating to: $route');

    Future.microtask(() {
      Navigator.pushReplacementNamed(context, route);
    });
  }

  /// Initialize services (non-blocking)
  void _initServices() async {
    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('⚠️ Notification init failed: $e');
    }

    try {
      final geminiKey = BuildConfigService.geminiApiKey;
      final openAiKey = BuildConfigService.openaiApiKey;
      final currentUser = FirebaseAuth.instance.currentUser;

      EnhancedAiService.instance.initialize(
        geminiKey,
        userId: currentUser?.uid,
        openAiKey: openAiKey,
      );
    } catch (e) {
      debugPrint('⚠️ AI init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/agri_base_icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            // Only show status message if there's actual text
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
