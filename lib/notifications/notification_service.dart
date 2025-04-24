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
import 'package:flutter/material.dart';
import 'package:firstapp/database/profile.dart' as workout;
import 'package:firstapp/providers_and_settings/program_provider.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';
import 'dart:convert'; // For jsonEncode/jsonDecode

tz.TZDateTime convertToTZDateTime(DateTime dateTime) {
  final location = tz.local; // Using device's local timezone
  return tz.TZDateTime.from(dateTime, location);
}

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
      const NotificationDetails(),
    );
  }

Future<void> scheduleWorkoutNotifications({
  required Profile profile,
  required SettingsModel settings,
  int daysInAdvance = 30,
}) async {
  if (!settings.notificationsEnabled) return;
  
  await initNotification();
  await cancelAllNotifications();

  final startDate = convertToTZDateTime(profile.origin);
  final endDate = startDate.add(Duration(days: daysInAdvance));
  final now = tz.TZDateTime.now(tz.local);

  for (final day in profile.split.where((d) => d.workoutTime != null)) {
    // Calculate the next occurrence first
    var currentDate = _nextOccurrence(day, profile, startDate);
    
    while (currentDate.isBefore(endDate)) {
      // Create notification time using the CORRECT date's components
      final scheduledDate = tz.TZDateTime(
        tz.local,
        currentDate.year,  // Use the future date's year
        currentDate.month, // Use the future date's month
        currentDate.day,   // Use the future date's day
        day.workoutTime!.hour,
        day.workoutTime!.minute,
      ).subtract(Duration(minutes: settings.timeReminder));

      // Double-check it's in the future
      if (scheduledDate.isAfter(now)) {
        await notificationsPlugin.zonedSchedule(
          _generateNotificationId(day, currentDate),
          'Workout Reminder',
          'Your ${day.dayTitle} starts soon!',
          scheduledDate,
          notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

          // mainly currently for debugging, but could be used to do something special upon notification press
          payload: jsonEncode({
            'workoutDayId': day.dayID,
            'scheduledTime': scheduledDate.toIso8601String(),
            'workoutTitle': day.dayTitle,
            'programDay': day.dayOrder,
          }),
        );
      }

      // Move to next occurrence
      currentDate = _nextOccurrence(day, profile, currentDate.add(Duration(days: 1)));
    }
  }
}

tz.TZDateTime _nextOccurrence(workout.Day day, Profile profile, tz.TZDateTime fromDate) {
  final programLength = profile.split.length;
  var date = fromDate;
  
  while (true) {
    final daysSinceStart = date.difference(fromDate).inDays;
    final dayInProgram = daysSinceStart % programLength;
    
    if (dayInProgram == day.dayOrder) {
      return date;
    }
    date = date.add(Duration(days: 1));
  }
}

  int _generateNotificationId(workout.Day day, DateTime date) {
    return day.dayID + date.day + date.month * 100 + date.year * 10000;
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  // for testing
  Future<String> debugPrintScheduledNotifications() async {
    String notifs = '';
    final pending = await notificationsPlugin.pendingNotificationRequests();
    
    debugPrint('📋 Pending Notifications (${pending.length})');
    pending.forEach((n) {
      debugPrint('''
      ID: ${n.id}
      Title: ${n.title}
      Body: ${n.body}
      Scheduled for: ${n.payload}
      '''); 
      notifs += '''
      ID: ${n.id}
      Title: ${n.title}
      Body: ${n.body}
      ${n.payload}
      ''';


    });

    return notifs;
  }

}