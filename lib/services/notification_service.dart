import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMealReminder() async {
    // Cancel existing reminders to avoid spam
    await flutterLocalNotificationsPlugin.cancelAll();

    // Schedule for 4 hours later
    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      const Duration(hours: 4),
      // const Duration(seconds: 10), // For testing
    );

    // Personalized messages
    final messages = [
      "Son öğününün üzerinden 4 saat geçti. Enerjini tazelemek için bir şeyler atıştırmaya ne dersin?",
      "Acıkmaya başladın mı? Öğle yemeği için Izgara Tavuk Salata harika bir seçim olabilir!",
      "Su içmeyi unutma! Ara öğün vakti yaklaşıyor. 💧",
      "Hedeflerine ulaşmak için düzenli beslenmek önemli. Bir sonraki öğününü planladın mı?",
      "Vücudun yakıt bekliyor! Sağlıklı bir şeyler yeme zamanı.",
    ];

    final randomMessage = messages[Random().nextInt(messages.length)];

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Öğün Vakti! 🍽️',
      randomMessage,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Öğün Hatırlatıcıları',
          channelDescription: 'Öğün vaktini hatırlatır',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
