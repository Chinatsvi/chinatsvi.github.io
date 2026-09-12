import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import '../../screens/auth/app_initializer.dart';
import 'package:agribased/screens/welcome_screen.dart';
import '../../screens/farmer_community_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/ask_ai_screen.dart';
import '../../screens/auth/farmer_auth_gateway.dart';
import '../../screens/auth/login_screen.dart';
import '../../widgets/tractor_loading.dart';
import '../../screens/test_feed_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/signup_choice_screen.dart';
// phone sign-in/up screens removed from routing; use email routes instead
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/marketplace/cart_screen.dart';
import '../../screens/marketplace/checkout_screen.dart';
import '../../screens/marketplace/my_orders_screen.dart';
import '../../screens/marketplace/orders_received_screen.dart';
import '../../screens/marketplace/item_details_page.dart';
import '../../screens/marketplace/report_item_page.dart';
import '../../screens/marketplace/boost_listing_page.dart';
import '../../screens/badge/verification_payment_screen.dart';
import '../../screens/post/boost_payment_screen.dart';
import '../../screens/badge/admin_verification_screen.dart';
import '../../screens/jobs/admin_job_verification_screen.dart';
import '../../screens/admin/moderation_dashboard.dart';
import '../../screens/academy/academy_screen.dart';
import '../../screens/admin/academy/academy_manager_screen.dart';
import '../../screens/mock_store_page.dart';

// Route constants
import 'app_routes.dart';
import '../services/auth_guard.dart';

class RouteGenerator {
  /// Wrap protected routes with authentication check
  static Route<dynamic> _wrapWithAuthGuard(Widget child, String routeName) {
    return MaterialPageRoute(
      builder: (context) =>
          AuthGuardWrapper(routeName: routeName, child: child),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint('🚀 [ROUTE] generateRoute called with: ${settings.name}');
    final args = settings.arguments;
    final routeName = settings.name;

    switch (routeName) {
      // Core
      case AppRoutes.appInitializer:
        return MaterialPageRoute(builder: (_) => const AppInitializer());
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      // Auth gateway
      case AppRoutes.authGateway:
        return MaterialPageRoute(builder: (_) => const FarmerAuthGateway());

      // Auth
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.signup:
        // Route `/signup` now shows the signup choice screen so callers
        // that still use AppRoutes.signup will land on the dedicated chooser.
        return MaterialPageRoute(builder: (_) => const SignUpChoiceScreen());
      case AppRoutes.signupChoice:
        return MaterialPageRoute(builder: (_) => const SignUpChoiceScreen());
      case AppRoutes.phoneSignIn:
        // Phone auth removed: redirect to email login
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.phoneSignUp:
        // Phone auth removed: redirect to regular sign up
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      // Entry point after login (auth handled by app_initializer)
      case AppRoutes.community:
        return MaterialPageRoute(builder: (_) => const FarmerCommunityScreen());

      // Community features (protected)
      case AppRoutes.chat:
        if (args is Map<String, dynamic>) {
          final chatId = args['chatId'] as String? ?? '';
          final otherUserId = args['otherUserId'] as String? ?? '';
          if (chatId.isEmpty || otherUserId.isEmpty) {
            return _errorRoute("Missing required chat parameters");
          }
          return _wrapWithAuthGuard(
            ChatScreen(chatId: chatId, otherUserId: otherUserId),
            AppRoutes.chat,
          );
        }
        return _errorRoute("Invalid arguments for chat route");

      // AI Assistant (protected)
      case AppRoutes.askAi:
        return _wrapWithAuthGuard(const AskAiScreen(), AppRoutes.askAi);

      // Marketplace (protected)
      case AppRoutes.cart:
        return _wrapWithAuthGuard(CartScreen(), AppRoutes.cart);
      case AppRoutes.checkout:
        if (args is Map<String, dynamic> && args.containsKey('selectedItems')) {
          final selectedItems =
              args['selectedItems'] as List<QueryDocumentSnapshot>;
          return _wrapWithAuthGuard(
            CheckoutScreen(selectedItems: selectedItems),
            AppRoutes.checkout,
          );
        }
        return _wrapWithAuthGuard(const CheckoutScreen(), AppRoutes.checkout);
      case AppRoutes.myOrders:
        return _wrapWithAuthGuard(MyOrdersScreen(), AppRoutes.myOrders);
      case AppRoutes.ordersReceived:
        return _wrapWithAuthGuard(
          const OrdersReceivedScreen(),
          AppRoutes.ordersReceived,
        );
      case AppRoutes.itemDetails:
        if (args is Map<String, dynamic>) {
          final item = args['item'];
          if (item == null) {
            return _errorRoute('Missing marketplace item data');
          }
          return _wrapWithAuthGuard(
            ItemDetailsPage(item: item),
            AppRoutes.itemDetails,
          );
        }
        return _errorRoute('Invalid arguments for item details');
      case AppRoutes.reportItem:
        if (args is String) {
          return _wrapWithAuthGuard(
            ReportItemPage(itemId: args),
            AppRoutes.reportItem,
          );
        }
        return _errorRoute('Invalid report item arguments');
      case AppRoutes.boostItem:
        if (args is String) {
          return _wrapWithAuthGuard(
            BoostListingPage(itemId: args),
            AppRoutes.boostItem,
          );
        }
        return _errorRoute('Invalid boost item arguments');

      // Payments (protected)
      case AppRoutes.verificationPayment:
        return _wrapWithAuthGuard(
          const VerificationPaymentScreen(),
          AppRoutes.verificationPayment,
        );
      case AppRoutes.boostPayment:
        if (args is Map<String, dynamic> &&
            args.containsKey('boostId') &&
            args.containsKey('boostData')) {
          return _wrapWithAuthGuard(
            BoostPaymentScreen(
              boostId: args['boostId'] as String,
              boostData: args['boostData'] as Map<String, dynamic>,
            ),
            AppRoutes.boostPayment,
          );
        }
        return _errorRoute('Invalid boost payment arguments');

      // Admin (protected)
      case AppRoutes.adminVerification:
        return _wrapWithAuthGuard(
          const AdminVerificationScreen(),
          AppRoutes.adminVerification,
        );
      case AppRoutes.adminJobVerification:
        return _wrapWithAuthGuard(
          const AdminJobVerificationScreen(),
          AppRoutes.adminJobVerification,
        );
      case AppRoutes.moderationDashboard:
        int initialTab = 0;
        if (args is int) {
          initialTab = args;
        } else if (args is Map<String, dynamic>) {
          initialTab = args['initialTab'] as int? ?? 0;
        }

        return _wrapWithAuthGuard(
          ModerationDashboard(initialTab: initialTab),
          AppRoutes.moderationDashboard,
        );

      case AppRoutes.academy:
        return MaterialPageRoute(builder: (_) => const AcademyScreen());

      case AppRoutes.adminAcademy:
        return _wrapWithAuthGuard(
          const AcademyManagerScreen(),
          AppRoutes.adminAcademy,
        );

      // Debug routes (protected)
      case AppRoutes.testFeed:
        return _wrapWithAuthGuard(const TestFeedScreen(), AppRoutes.testFeed);
      case AppRoutes.mockStore:
        if (args is Map<String, dynamic> && args.containsKey('userId')) {
          final userId = args['userId'] as String;
          return _wrapWithAuthGuard(
            MockStorePage(userId: userId),
            AppRoutes.mockStore,
          );
        }
        return _errorRoute('Missing userId for mock store');

      // Unknown route
      default:
        return _errorRoute("Route not found: $routeName");
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(message)),
      ),
    );
  }
}

/// Widget to wrap protected routes with authentication check
class AuthGuardWrapper extends StatefulWidget {
  final Widget child;
  final String routeName;

  const AuthGuardWrapper({
    super.key,
    required this.child,
    required this.routeName,
  });

  @override
  State<AuthGuardWrapper> createState() => _AuthGuardWrapperState();
}

class _AuthGuardWrapperState extends State<AuthGuardWrapper> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuthenticated = await AuthGuard.isUserAuthenticated();
    if (!mounted) return;

    if (!isAuthenticated) {
      // 🔥 Navigate away - don't show empty widget
      AuthGuard.showAuthError(context);
      AuthGuard.redirectToAuth(context);
      return;
    }

    setState(() => _isCheckingAuth = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(body: Center(child: TractorLoading()));
    }

    return widget.child;
  }
}
