import 'package:firebase_messaging/firebase_messaging.dart';

import '../device_capability_service.dart';
import 'push_service.dart';

class FcmPushService implements PushService {
  FcmPushService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  Future<String?> getToken() async {
    if (!await DeviceCapabilityService.instance.canUseFirebaseMessaging) {
      return null;
    }
    return await _messaging.getToken();
  }

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    if (!await DeviceCapabilityService.instance.canUseFirebaseMessaging) {
      return null;
    }
    return await _messaging.getInitialMessage();
  }

  @override
  Future<NotificationSettings> requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  @override
  Future<void> initialize() async {
    if (!await DeviceCapabilityService.instance.canUseFirebaseMessaging) {
      return;
    }
    // No explicit initialization required for firebase_messaging on mobile.
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
