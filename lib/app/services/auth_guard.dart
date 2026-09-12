import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/app/routes/app_routes.dart';
import 'package:agribased/services/auth_service.dart';

class AuthGuard {
  static const List<String> protectedRoutes = [
    AppRoutes.community,
    AppRoutes.chat,
    AppRoutes.askAi,
    AppRoutes.cart,
    AppRoutes.checkout,
    AppRoutes.myOrders,
    AppRoutes.ordersReceived,
    AppRoutes.itemDetails,
    AppRoutes.reportItem,
    AppRoutes.boostItem,
    AppRoutes.verificationPayment,
    AppRoutes.adminVerification,
    AppRoutes.moderationDashboard,
  ];

  static const List<String> publicRoutes = [
    AppRoutes.splash,
    AppRoutes.welcome,
    AppRoutes.authGateway,
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.forgotPassword,
  ];

  /// ✅ ROBUST AUTH CHECK (NO FLICKER, NO FALSE LOGOUT)
  static Future<bool> isUserAuthenticated() async {
    try {
      // Direct Firebase check - most reliable
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('✅ [AUTH GUARD] Firebase user found: ${currentUser.uid}');
        return true;
      }

      debugPrint('⏳ [AUTH GUARD] No immediate user, checking AuthService...');
      // Use centralized AuthService as backup
      await AuthService.instance.init();
      final fast = AuthService.instance.isAuthenticatedSync();
      if (fast) {
        debugPrint('✅ [AUTH GUARD] AuthService cached user');
        return true;
      }

      // Don't wait for restore - if user was logged in, Firebase persistence should handle it
      // Only return false if we're certain there's no user
      debugPrint('❌ [AUTH GUARD] No user found');
      return false;
    } catch (e) {
      debugPrint('❌ [AUTH GUARD ERROR]: $e');
      // Fail safe: don't block if currentUser exists
      return FirebaseAuth.instance.currentUser != null;
    }
  }

  /// ✅ Check if route requires authentication
  static bool isProtectedRoute(String? routeName) {
    if (routeName == null) return false;
    return protectedRoutes.contains(routeName);
  }

  /// ✅ SAFE REDIRECT for protected routes
  static void redirectToAuth(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
  }

  /// ✅ Show authentication error message
  static void showAuthError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please sign in to access this feature.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}