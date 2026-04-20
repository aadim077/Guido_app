import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/navigation_key.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 42;

  static const List<String> _messages = [
    "Your daily Python practice is waiting. Keep the streak going!",
    "A few minutes of coding today keeps the rust away. Open Guido!",
    "Ready to level up? Your lessons are waiting for you.",
    "Consistency beats intensity. Just 10 minutes today makes a difference.",
    "You are one lesson closer to your certificate. Let us go!",
  ];

  Future<void> initializeNotifications() async {
    if (kIsWeb) {
      debugPrint("Notifications not supported on web.");
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (kIsWeb) {
      debugPrint("Notifications not supported on web.");
      return;
    }

    await cancelReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'guido_reminders',
      'Daily Study Reminders',
      channelDescription: 'Daily reminders to study on Guido',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    final messageOfTheDay = _messages[now.weekday % _messages.length];

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _notificationId,
      'Guido - Time to Learn!',
      messageOfTheDay,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[NotificationService] Scheduled at: $scheduledDate (local: ${tz.local.name})');
  }

  Future<void> cancelReminder() async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin.cancel(_notificationId);
  }

  Future<bool> isNotificationScheduled() async {
    if (kIsWeb) return false;
    final List<PendingNotificationRequest> pending =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pending.any((element) => element.id == _notificationId);
  }

  /// Shows an immediate notification for testing — works in all build modes.
  Future<void> showTestNotification() async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'guido_reminders',
      'Daily Study Reminders',
      channelDescription: 'Daily reminders to study on Guido',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      99,
      'Guido - Test Notification',
      'Your reminders are working correctly!',
      notificationDetails,
    );
  }

  /// Schedules a one-off notification 10 seconds from now.
  /// Use in debug mode on an emulator to verify scheduled alarms fire correctly.
  Future<void> scheduleTestIn10Seconds() async {
    if (kIsWeb) return;

    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'guido_reminders',
      'Daily Study Reminders',
      channelDescription: 'Daily reminders to study on Guido',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      98, // separate ID — won't cancel the real daily reminder
      'Guido - Scheduled Test 🎉',
      'Scheduled alarms are working correctly!',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // No matchDateTimeComponents → fires once only, not daily
    );

    debugPrint('[NotificationService] 10s test alarm scheduled for: $scheduledDate');
  }
}
