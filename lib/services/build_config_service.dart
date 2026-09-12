import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple service to read BuildConfig values without external dependencies
class BuildConfigService {
  /// Get Gemini API key from Dart define or environment variable.
  /// Use `--dart-define=GEMINI_API_KEY=<key>` when building or running.
  static String get geminiApiKey => const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Get OpenAI API key from Dart define or environment variable.
  /// Use `--dart-define=OPENAI_API_KEY=<key>` when building or running.
  static String get openaiApiKey => const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  /// Set your deployed Cloudflare moderation worker URL via Dart define.
  /// Example: `--dart-define=MODERATION_WORKER_URL=https://agribased-moderation.workers.dev`
  static String get moderationWorkerUrl => const String.fromEnvironment('MODERATION_WORKER_URL', defaultValue: '');

  /// Check if a Cloudflare moderation worker URL is configured.
  static bool get hasModerationWorkerUrl => moderationWorkerUrl.isNotEmpty;

  /// Check if Gemini API key is available
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;

  /// Check if OpenAI API key is available
  static bool get hasOpenaiApiKey => openaiApiKey.isNotEmpty;

  /// AdMob App ID
  static String get admobAppId =>
      dotenv.env['ADMOB_APP_ID'] ??
      const String.fromEnvironment(
        'ADMOB_APP_ID',
        defaultValue: 'ca-app-pub-2606126305565597~6598731736',
      );

  /// AdMob Banner Ad Unit ID
  static String get admobBannerAdUnitId =>
      dotenv.env['ADMOB_BANNER_AD_UNIT_ID'] ??
      const String.fromEnvironment(
        'ADMOB_BANNER_AD_UNIT_ID',
        defaultValue: 'ca-app-pub-2606126305565597/1136425567',
      );

  /// ImageKit Public Key for client-side uploads
  static String get imagekitPublicKey =>
      dotenv.env['IMAGEKIT_PUBLIC_KEY'] ??
      const String.fromEnvironment(
        'IMAGEKIT_PUBLIC_KEY',
        defaultValue: 'public_eh5I9CcyYCU+//KN2YHJ/jxcOM0=',
      );

  /// ImageKit URL Endpoint / CDN Base URL
  static String get imagekitUrlEndpoint =>
      dotenv.env['IMAGEKIT_URL_ENDPOINT'] ??
      const String.fromEnvironment(
        'IMAGEKIT_URL_ENDPOINT',
        defaultValue: 'https://ik.imagekit.io/tm9mps54c',
      );

  /// ImageKit Authentication endpoint URL (on Cloudflare Worker)
  static String get imagekitAuthUrl {
    final customAuthUrl = dotenv.env['IMAGEKIT_AUTH_URL'] ??
        const String.fromEnvironment('IMAGEKIT_AUTH_URL', defaultValue: '');
    if (customAuthUrl.isNotEmpty) return customAuthUrl;

    if (moderationWorkerUrl.isNotEmpty) {
      final base = moderationWorkerUrl.endsWith('/')
          ? moderationWorkerUrl.substring(0, moderationWorkerUrl.length - 1)
          : moderationWorkerUrl;
      return '$base/imagekit-auth';
    }

    return 'https://agribased-moderation.chinatsvieno.workers.dev/imagekit-auth';
  }

  /// Use mock billing flows instead of Google Play in development/testing.
  /// Set to `false` before production release when Play Billing should be used.
  static bool get useMockBilling => true;
}
