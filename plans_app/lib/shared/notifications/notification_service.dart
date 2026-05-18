import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/tasks/models/task.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static AndroidScheduleMode _androidScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      tz.initializeTimeZones();
      final localTz = (await FlutterTimezone.getLocalTimezone()).identifier;
      debugPrint('NotificationService: timezone=$localTz');
      try {
        tz.setLocalLocation(tz.getLocation(localTz));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
        debugPrint('NotificationService: unknown tz, falling back to UTC');
      }

      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_stat_notification');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final settings = InitializationSettings(
        android: androidSettings,
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
        macOS: darwinSettings,
      );

      final initResult = await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      debugPrint('NotificationService: initialize=$initResult');

      if (Platform.isMacOS) {
        final permStatus = await _plugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        _initialized = permStatus?.isEnabled == true;
        debugPrint(
          'NotificationService: macOS enabled=$_initialized',
        );
      } else if (Platform.isIOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        _initialized = granted == true;
        debugPrint('NotificationService: iOS granted=$granted');
      } else if (Platform.isAndroid) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        // null return means pre-Android-13 where permission is always granted
        final granted = await androidPlugin?.requestNotificationsPermission();
        _initialized = granted != false;
        debugPrint(
          'NotificationService: Android granted=$granted _initialized=$_initialized',
        );
        if (_initialized) {
          final canExact =
              await androidPlugin?.canScheduleExactNotifications() ?? false;
          _androidScheduleMode = canExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle;
          debugPrint(
            'NotificationService: canExact=$canExact mode=$_androidScheduleMode',
          );
        }
      }
    } catch (e, st) {
      debugPrint('NotificationService.init failed: $e\n$st');
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {}

  static int _dueId(String taskId) => taskId.hashCode.abs() % 0x3FFFFFFF;
  static int _reminderId(String taskId) =>
      (_dueId(taskId) + 0x40000000) % 0x7FFFFFFF;

  static Future<void> scheduleForTask(Task task) async {
    if (!_initialized) {
      debugPrint(
        'NotificationService: skip scheduleForTask — not initialized',
      );
      return;
    }
    await cancelForTask(task.id);
    if (task.dueDate == null || task.isCompleted) return;

    final now = tz.TZDateTime.now(tz.local);
    final dueTime = tz.TZDateTime.from(task.dueDate!, tz.local);
    debugPrint(
      'NotificationService: scheduleForTask "${task.title}" due=$dueTime now=$now future=${dueTime.isAfter(now)}',
    );

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
    await _plugin.cancel(id: _dueId(taskId));
    await _plugin.cancel(id: _reminderId(taskId));
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
        id: id,
        title: title,
        body: body,
        scheduledDate: at,
        notificationDetails: NotificationDetails(
          macOS: const DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          android: const AndroidNotificationDetails(
            'plans_reminders',
            'Task Reminders',
            channelDescription: 'Task due date and reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notification',
          ),
        ),
        androidScheduleMode: _androidScheduleMode,
      );
      debugPrint('NotificationService: scheduled id=$id "$title" at $at');
    } catch (e, st) {
      debugPrint('NotificationService._schedule failed: $e\n$st');
    }
  }
}
