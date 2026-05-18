import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/tasks/models/task.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      final localTz = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(localTz));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(macOS: darwinSettings);
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Verify permission status (AppDelegate.swift handles native request)
      final permStatus = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      debugPrint(
        'NotificationService: notifications enabled = ${permStatus?.isEnabled}',
      );
      _initialized = permStatus?.isEnabled == true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {}

  static int _dueId(String taskId) => taskId.hashCode.abs() % 0x3FFFFFFF;
  static int _reminderId(String taskId) =>
      (_dueId(taskId) + 0x40000000) % 0x7FFFFFFF;

  static Future<void> scheduleForTask(Task task) async {
    if (!_initialized) return;
    await cancelForTask(task.id);
    if (task.dueDate == null || task.isCompleted) return;

    final now = tz.TZDateTime.now(tz.local);
    final dueTime = tz.TZDateTime.from(task.dueDate!, tz.local);

    if (dueTime.isAfter(now)) {
      await _schedule(
        id: _dueId(task.id),
        title: task.title,
        body: 'Due now',
        at: dueTime,
      );
    }

    final rem = task.reminderMinutes;
    if (rem != null && rem > 0) {
      final reminderTime = dueTime.subtract(Duration(minutes: rem));
      if (reminderTime.isAfter(now)) {
        await _schedule(
          id: _reminderId(task.id),
          title: task.title,
          body: 'Due in $rem ${rem == 1 ? "minute" : "minutes"}',
          at: reminderTime,
        );
      }
    }
  }

  static Future<void> cancelForTask(String taskId) async {
    if (!_initialized) return;
    await _plugin.cancel(_dueId(taskId));
    await _plugin.cancel(_reminderId(taskId));
  }

  static Future<void> rescheduleAll(List<Task> tasks) async {
    if (!_initialized) return;
    for (final task in tasks) {
      if (!task.isCompleted && task.dueDate != null) {
        await scheduleForTask(task);
      }
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        at,
        const NotificationDetails(
          macOS: DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('NotificationService: scheduled id=$id "$title" at $at');
    } catch (e) {
      debugPrint('NotificationService._schedule failed: $e');
    }
  }
}
