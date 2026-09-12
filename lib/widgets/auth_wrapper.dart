import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_wrapper_provider.dart';
import '../services/auth/auth_initialization_service.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  final Widget? child;

  const AuthWrapper({super.key, this.child});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authInitializationControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authGuard = ref.watch(authGuardProvider);
    final userSession = ref.watch(userSessionInfoProvider);

    return authGuard.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing authentication...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Authentication Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(authInitializationControllerProvider.notifier)
                      .initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (isAuthenticated) {
        // Debug information
        if (userSession != null) {
          debugPrint('🔑 User Session: ${userSession['email']}');
          debugPrint('🔑 Authenticated: ${userSession['isAuthenticated']}');
          debugPrint('🔑 Last Sign In: ${userSession['lastSignInTime']}');
        }

        if (isAuthenticated && userSession != null) {
          // User is authenticated, show main app
          if (widget.child != null) {
            return widget.child!;
          }
          // Placeholder home screen - replace with your actual home screen
          return const Scaffold(
            body: Center(
              child: Text('Home Screen - Replace with your actual home screen'),
            ),
          );
        } else {
          // User is not authenticated, show login screen
          // Placeholder login screen - replace with your actual login screen
          return const Scaffold(
            body: Center(
              child: Text(
                'Login Screen - Replace with your actual login screen',
              ),
            ),
          );
        }
      },
    );
  }
}

/// Splash screen widget for better UX during auth initialization
class AuthSplashScreen extends StatelessWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.agriculture,
                size: 60,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            const Text(
              'AgriBase',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Smart Farming Solution',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 64),

            // Loading indicator
            const Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Auth Wrapper with splash screen
class EnhancedAuthWrapper extends ConsumerWidget {
  final Widget child;

  const EnhancedAuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authGuard = ref.watch(authGuardProvider);

    return authGuard.when(
      loading: () => const AuthSplashScreen(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Authentication Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(authInitializationControllerProvider.notifier)
                      .initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (isAuthenticated) {
        final userSession = ref.watch(userSessionInfoProvider);

        if (isAuthenticated && userSession != null) {
          return child;
        } else {
          // Placeholder login screen - replace with your actual login screen
          return const Scaffold(
            body: Center(
              child: Text(
                'Login Screen - Replace with your actual login screen',
              ),
            ),
          );
        }
      },
    );
  }
}
