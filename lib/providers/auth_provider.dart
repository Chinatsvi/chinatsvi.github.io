import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth/firebase_auth_service.dart';

// Authentication Service Provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Authentication State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

// Authentication Controller
class AuthController extends AsyncNotifier<void> {
  late final FirebaseAuthService _authService;

  @override
  Future<void> build() async {
    _authService = ref.watch(authServiceProvider);
  }

  // Email/Password Sign Up
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUpWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Email/Password Sign In
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Phone Sign In
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    required Duration timeout,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerificationFailed: (e) {
          state = AsyncValue.error(e, StackTrace.current);
          onVerificationFailed(e.message ?? 'Unknown error');
        },
        onVerificationCompleted: (credential) async {
          try {
            await _authService.signInWithPhoneCredential(
              verificationId: credential.verificationId ?? '',
              smsCode: credential.smsCode ?? '',
            );
            state = const AsyncValue.data(null);
          } catch (e) {
            state = AsyncValue.error(e, StackTrace.current);
          }
        },
        timeout: timeout,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Verify Phone Code
  Future<void> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithPhoneCredential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Clear Error State
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

// Auth Controller Provider
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

// Authentication Status Provider
final authStatusProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// User Information Providers
final userDisplayNameProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userDisplayName;
});

final userEmailProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userEmail;
});

final userPhotoURLProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userPhotoURL;
});

final userUIDProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userUID;
});
