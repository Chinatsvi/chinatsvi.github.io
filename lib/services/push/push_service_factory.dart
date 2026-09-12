import 'package:agribased/services/device_capability_service.dart';

import 'fcm_push_service.dart';
import 'noop_push_service.dart';
import 'push_service.dart';

class PushServiceFactory {
  PushServiceFactory._();

  static Future<PushService> create() async {
    final hasFcm = await DeviceCapabilityService.instance.canUseFirebaseMessaging;
    if (hasFcm) {
      return FcmPushService();
    }
    return NoOpPushService();
  }
}
