import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitlens/services/notification_service.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 User granted permission: ${settings.authorizationStatus}');

    // 2. GET THE TOKEN (The "Phone Number" for this specific device)
    String? token = await _firebaseMessaging.getToken();
    print("🔥 ==================================================");
    print("🔥 COPY THIS TOKEN FOR FIREBASE CONSOLE:");
    print("🔥 $token");
    print("🔥 ==================================================");

    // 3. Handle Foreground Messages (If app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Message received in foreground!');
      if (message.notification != null) {
        // Use your existing Local Notification to show the popup
        NotificationService.showWarning(
          message.notification!.title ?? "Reminder", 
          message.notification!.body ?? "Check your meals!"
        );
      }
    });
  }
}
