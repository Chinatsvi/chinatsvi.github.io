import 'package:firebase_messaging/firebase_messaging.dart';

abstract class PushService {
  Future<void> initialize();
  Future<NotificationSettings> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<RemoteMessage?> getInitialMessage();
}
