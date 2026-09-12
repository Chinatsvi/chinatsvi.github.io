import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth/auth_initialization_service.dart';

// Auth Initialization Service Provider
final authInitializationServiceProvider = Provider<AuthInitializationService>((
  ref,
) {
  return AuthInitializationService();
});

// Enhanced Auth State Provider with proper initialization
final enhancedAuthStateProvider = StreamProvider<User?>((ref) async* {
  final authService = ref.watch(authInitializationServiceProvider);

  // Wait for initialization before emitting auth state
  await authService.initialize();

  // Now emit the auth state stream
  yield* FirebaseAuth.instance.authStateChanges();
});

// Authentication Status Provider with validation
final authStatusProvider = Provider<bool>((ref) {
  final authService = ref.watch(authInitializationServiceProvider);
  final authState = ref.watch(enhancedAuthStateProvider);

  // Only return true if user is properly authenticated
  return authState.value != null && authService.isUserAuthenticated;
});

// Current Validated User Provider
final currentValidatedUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authInitializationServiceProvider);
  return authService.validatedUser;
});

// Auth Initialization Controller
class AuthInitializationController extends AsyncNotifier<void> {
  late final AuthInitializationService _authService;

  @override
  Future<void> build() async {
    _authService = ref.watch(authInitializationServiceProvider);
    await initialize();
  }

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      await _authService.initialize();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshUser() async {
    try {
      await _authService.refreshUser();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void debugAuthState() {
    _authService.debugAuthState();
  }
}

// Auth Initialization Controller Provider
final authInitializationControllerProvider =
    AsyncNotifierProvider<AuthInitializationController, void>(
      AuthInitializationController.new,
    );

// Authentication Guard Provider
final authGuardProvider = Provider<AsyncValue<bool>>((ref) {
  final initializationState = ref.watch(authInitializationControllerProvider);
  final authStatus = ref.watch(authStatusProvider);

  if (initializationState.isLoading) {
    return const AsyncValue.loading();
  }

  if (initializationState.hasError) {
    return AsyncValue.error(initializationState.error!, StackTrace.current);
  }

  return AsyncValue.data(authStatus);
});

// User Session Info Provider
final userSessionInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentValidatedUserProvider);
  final authService = ref.watch(authInitializationServiceProvider);

  if (user == null) return null;

  return {
    'email': user.email,
    'uid': user.uid,
    'displayName': user.displayName,
    'photoURL': user.photoURL,
    'emailVerified': user.emailVerified,
    'creationTime': user.metadata.creationTime?.toIso8601String(),
    'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
    'isAuthenticated': authService.isUserAuthenticated,
  };
});
