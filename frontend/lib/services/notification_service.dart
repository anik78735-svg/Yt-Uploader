import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static const String oneSignalAppId = "04df9533-a8db-4ff5-b808-b57684528707"; // 👈 Yahan App ID daalo

  static Future<void> init() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.error);
      OneSignal.initialize(oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);
      debugPrint("✅ OneSignal initialized");
    } catch (e) {
      debugPrint("OneSignal init error: $e");
    }
  }
}
