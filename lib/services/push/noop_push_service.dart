import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_service.dart';

class NoOpPushService implements PushService {
  NoOpPushService();

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationSettings> requestPermission() async {
    return await FirebaseMessaging.instance.requestPermission();
  }

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<RemoteMessage> get onMessage => const Stream<RemoteMessage>.empty();

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream<RemoteMessage>.empty();

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
}
