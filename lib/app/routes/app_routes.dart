class AppRoutes {
  // Core
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String appInitializer = '/app-initializer';

  // Auth
  static const String authGateway = '/auth-gateway';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String signupChoice = '/signup-choice';
  static const String phoneSignIn = '/phone-signin';
  static const String phoneSignUp = '/phone-signup';
  static const String forgotPassword = '/forgot-password';

  // Marketplace
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String myOrders = '/my-orders';
  static const String ordersReceived = '/orders-received';
  static const String itemDetails = '/item-details';
  static const String reportItem = '/marketplace/report';
  static const String boostItem = '/marketplace/boost';

  // Main App
  static const String community = '/community';
  static const String chat = '/chat';
  static const String askAi = '/ask-ai';

  // Payments
  static const String verificationPayment = '/verification-payment';
  static const String boostPayment = '/boost-payment';

  //
  static const adminVerification = '/admin-verification';
  static const adminJobVerification = '/admin-job-verification';
  static const moderationDashboard = '/moderation-dashboard';

  // Academy
  static const String academy = '/academy';
  static const String adminAcademy = '/admin/academy';

  // Debug
  static const testFeed = '/test-feed';
  static const mockStore = '/mock-store';
  static const backfillBoosts = '/admin/backfill-boosts';
}
