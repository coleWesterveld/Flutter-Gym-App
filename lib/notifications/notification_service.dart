// This serves local notificiations for upcoming workouts
// Reminds user of equipment to bring, as specified by user
// Reminds user X mins/hrs before workout -- user defined in settings page

// followed this tutorial: 
// Pt 1. https://www.youtube.com/watch?v=uKz8tWbMuUw
// Pt 2. https://www.youtube.com/watch?v=i98p9dJ4lhI


// TODO: make sure it runs on day reordering - it crashed for me when I toggled notifs, reordered days
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

  final bool _isInitialized = false;

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

    final originDate = convertToTZDateTime(profile.origin);
    debugPrint("origin: ${profile.origin}");
    final now = tz.TZDateTime.now(tz.local);
    final endDate = now.add(Duration(days: daysInAdvance));

    for (final day in profile.split) {
      // Find the first occurrence after origin date
      var currentDate = _nextOccurrence(day, profile, originDate);
      
      // Only schedule dates between now and endDate
      while (currentDate.isBefore(endDate)) {
        if (day.dayTitle == "Push"){
          debugPrint("scheduling for: ${currentDate}");
        }
        // Skip if this date is in the past
        if (currentDate.isBefore(now)) {
          if (day.dayTitle == "Push"){
            debugPrint("WARN for: ${currentDate}");
          }
          currentDate = _nextOccurrence(day, profile, currentDate.add(const Duration(days: 1)));
          continue;
        }

        // Create notification time (workout time - reminder offset)
        final notificationTime = tz.TZDateTime(
          tz.local,
          currentDate.year,
          currentDate.month,
          currentDate.day,
          day.workoutTime?.hour ?? 8,
          day.workoutTime?.minute ?? settings.timeReminder,
        ).subtract(Duration(minutes: settings.timeReminder));

        // Only schedule if the reminder time is still in the future
        if (notificationTime.isAfter(now)) {
          if (day.dayTitle == "Push"){
            debugPrint("SUCCESS for: ${currentDate}");
          }
          await notificationsPlugin.zonedSchedule(
            _generateNotificationId(day, currentDate),
            '${day.dayTitle} Workout Starts Soon',
            day.gear.isEmpty ? 'Don\'t forget any gear you need!' : 'Don\'t forget: ${day.gear}',
            notificationTime,
            notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: jsonEncode({
              'workoutDayId': day.dayID,
              'scheduledTime': notificationTime.toIso8601String(),
              'workoutTitle': day.dayTitle,
              'programDay': day.dayOrder,
            }),
          );
        }

        // Move to next occurrence in the program cycle
        currentDate = _nextOccurrence(day, profile, currentDate.add(const Duration(days: 1)));
      }
    }
  }

  tz.TZDateTime _nextOccurrence(workout.Day day, Profile profile, tz.TZDateTime fromDate) {
    final programLength = profile.splitLength; // Using splitLength instead of split.length
    var date = fromDate;
    
    while (true) {
      final daysSinceOrigin = date.difference(convertToTZDateTime(profile.origin)).inDays;
      final dayInProgram = daysSinceOrigin % programLength;
      
      if (dayInProgram == day.dayOrder) { // Keep dayOrder as-is (matches getEventsForDay)
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
  }

  // jeez this was overflowing which then caused ID collisions messing up my notifications
  // now its fixed 
  int _generateNotificationId(workout.Day day, DateTime date) {
    // The maximum value for a notification ID is the max for a 32-bit signed integer (2,147,483,647).
    // We construct a unique ID by combining year, day of year, and the workout's ID.
    // This ensures that the ID is unique for every workout on every day.

    // To prevent the final number from becoming too large, we can use an offset for the year.
    // This is just to keep the number smaller; it does not affect the uniqueness.
    // Using 2024 as the epoch makes the logic clear that it's based on a recent year.
    const int yearEpoch = 2024;
    final int year = date.year - yearEpoch;

    // Day of year ranges from 1 to 366.
    final int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;

    // We combine these parts by multiplying them by factors of 10, ensuring no overlap.
    // The multiplier of 1000 for dayOfYear reserves 3 digits for day.dayID (0-999).
    // Example for dayID 999 on Dec 31, 2025: (1 * 1000000) + (365 * 1000) + 999 = 1,365,999
    final int uniqueId = year * 1000000 + dayOfYear * 1000 + day.dayID;
    
    // This approach is safe for thousands of years and handles day.dayID up to 999.
    return uniqueId;
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
    for (var n in pending) {
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


    }

    return notifs;
  }

}