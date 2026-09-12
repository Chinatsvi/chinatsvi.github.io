import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../services/notifications/notification_service.dart';

// Import new livestock providers
import 'livestock_provider.dart';
import 'enhanced_animal_provider.dart';
import 'enhanced_poultry_provider.dart';

// SINGLE CLEAN PROVIDERS - NO CONFLICTS
final authProvider = Provider<AuthController>((ref) => AuthController());

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

// Livestock management providers
final enhancedAnimalRepositoryProvider = Provider<EnhancedAnimalRepository>(
  (ref) => EnhancedAnimalRepository(),
);

final enhancedPoultryRepositoryProvider = Provider<EnhancedPoultryRepository>(
  (ref) => EnhancedPoultryRepository(),
);

final livestockServiceProvider = Provider<LivestockService>(
  (ref) => LivestockService(
    animalRepo: ref.watch(enhancedAnimalRepositoryProvider),
    poultryRepo: ref.watch(enhancedPoultryRepositoryProvider),
  ),
);
