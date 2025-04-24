// This serves local notificiations for upcoming workouts
// Reminds user of equipment to bring, as specified by user
// Reminds user X mins/hrs before workout -- user defined in settings page

// followed this tutorial: 
// Pt 1. https://www.youtube.com/watch?v=uKz8tWbMuUw
// Pt 2. https://www.youtube.com/watch?v=i98p9dJ4lhI

// TODO: test on both android and IOS, there may be some other stuff I gotta do 

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // INITIALIZE
  Future<void> initNotification() async {
    // prevent reinitialization
    if (_isInitialized) return;

    // initialize timezone
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    // prepare android init settings
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    // prepare ios init settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // init settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    // finally, init plugin
    await notificationsPlugin.initialize(initSettings);
  }

  // NOTIFICATIONS DETAIL SETUP
  NotificationDetails notificationDetails(){
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id', 
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high
      ),

      iOS: DarwinNotificationDetails(),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notificationsPlugin.show(
      id, 
      title, 
      body, 
      const NotificationDetails()
    );
  }

  /*
  Schedule notifications for specified time
  - hour (0-23)
  - minute (0-59)
  */

  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute
  }) async {
    // Get current datetime in local timezone
    final now = tz.TZDateTime.now(tz.local);

    // Create a date/time for notification to come up at
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute
    );

    // Schedule it at the specified time
    await notificationsPlugin.zonedSchedule(
      id, 
      title, 
      body, 
      scheduledDate, 
      const NotificationDetails(), 
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }


}