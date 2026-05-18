import 'dart:io' show Platform;
import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/tasks/models/task.dart';

class NotificationService {
  // flutter_local_notifications used for macOS scheduling + Android permission
  static final _fln = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      if (Platform.isMacOS) {
        await _initMacOS();
      } else {
        await _initMobile();
      }
    } catch (e, st) {
      debugPrint('NotificationService.init failed: $e\n$st');
    }
  }

  // ── macOS ────────────────────────────────────────────────────────────────

  static Future<void> _initMacOS() async {
    tz.initializeTimeZones();
    final localTz = (await FlutterTimezone.getLocalTimezone()).identifier;
    try {
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    debugPrint('NotificationService: macOS tz=$localTz');

    const settings = InitializationSettings(
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _fln.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    final permStatus = await _fln
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    _initialized = permStatus?.isEnabled == true;
    debugPrint('NotificationService: macOS initialized=$_initialized');
  }

  // ── iOS / Android ────────────────────────────────────────────────────────

  static Future<void> _initMobile() async {
    await Alarm.init();
    debugPrint('NotificationService: Alarm.init() done');

    if (Platform.isAndroid) {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_notification'),
      );
      await _fln.initialize(settings: settings);
      final androidPlugin = _fln
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      _initialized = granted != false;
      debugPrint(
        'NotificationService: Android permission granted=$granted initialized=$_initialized',
      );
    } else {
      // iOS permission requested automatically by alarm package on first use
      _initialized = true;
    }

    // When alarm fires: stop the service first (no user input needed — vibrate=false
    // means nothing is looping), then show a dismissible _fln notification.
    Alarm.ringing.listen((alarmSet) async {
      for (final alarm in alarmSet.alarms) {
        await Alarm.stop(alarm.id);
        try {
          await _fln.show(
            id: alarm.id,
            title: alarm.notificationSettings.title,
            body: alarm.notificationSettings.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'plans_reminders',
                'Task Reminders',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@drawable/ic_stat_notification',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentSound: false,
                presentBadge: false,
              ),
            ),
          );
          debugPrint('NotificationService: shown id=${alarm.id} "${alarm.notificationSettings.title}"');
        } catch (e, st) {
          debugPrint('NotificationService: fln.show FAILED: $e\n$st');
        }
      }
    });
  }

  static void _onResponse(NotificationResponse response) {}

  // ── ID helpers ───────────────────────────────────────────────────────────

  static int _dueId(String taskId) {
    final h = taskId.hashCode.abs() % 0x3FFFFFFF;
    return h == 0 ? 1 : h;
  }

  static int _reminderId(String taskId) {
    final h = (_dueId(taskId) + 0x40000000) % 0x7FFFFFFF;
    return h == 0 ? 1 : h;
  }

  // ── Public API ───────────────────────────────────────────────────────────

  static Future<void> scheduleForTask(Task task) async {
    if (!_initialized) {
      debugPrint('NotificationService: skip — not initialized');
      return;
    }
    await cancelForTask(task.id);
    if (task.dueDate == null || task.isCompleted) return;

    final now = DateTime.now();
    final dueTime = task.dueDate!;
    final secondsPast = now.difference(dueTime).inSeconds;
    debugPrint(
      'NotificationService: scheduleForTask "${task.title}" due=$dueTime secondsPast=$secondsPast',
    );

    if (secondsPast >= 60) return;

    final fireAt =
        dueTime.isAfter(now) ? dueTime : now.add(const Duration(seconds: 5));

    await _scheduleNotification(
      id: _dueId(task.id),
      title: task.title,
      body: 'Due now',
      at: fireAt,
    );

    final rem = task.reminderMinutes;
    if (rem != null && rem > 0) {
      final reminderTime = dueTime.subtract(Duration(minutes: rem));
      if (reminderTime.isAfter(now)) {
        await _scheduleNotification(
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
    if (Platform.isMacOS) {
      await _fln.cancel(id: _dueId(taskId));
      await _fln.cancel(id: _reminderId(taskId));
    } else {
      await Alarm.stop(_dueId(taskId));
      await Alarm.stop(_reminderId(taskId));
      await _fln.cancel(id: _dueId(taskId));
      await _fln.cancel(id: _reminderId(taskId));
    }
  }

  static Future<void> rescheduleAll(List<Task> tasks) async {
    if (!_initialized) return;
    // Android/iOS: Alarm.init() restores scheduled alarms from SharedPreferences
    if (!Platform.isMacOS) return;
    for (final task in tasks) {
      if (!task.isCompleted && task.dueDate != null) {
        await scheduleForTask(task);
      }
    }
  }

  static Future<void> showTestNotification() async {
    if (!_initialized) {
      debugPrint('NotificationService: showTestNotification — not initialized');
      return;
    }
    try {
      // Instant notification via show()
      await _fln.show(
        id: 999998,
        title: 'Plans — instant test',
        body: 'show() works (no AlarmManager)',
        notificationDetails: const NotificationDetails(
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
          android: AndroidNotificationDetails(
            'plans_reminders',
            'Task Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notification',
          ),
        ),
      );
      debugPrint('NotificationService: instant test sent');

      // Scheduled test via alarm package — fires in 10 seconds
      final fireAt =
          DateTime.now().add(const Duration(seconds: 10));
      await _scheduleNotification(
        id: 999999,
        title: 'Plans — alarm test',
        body: 'Alarm-based notification fired!',
        at: fireAt,
      );
      debugPrint('NotificationService: alarm test scheduled for $fireAt');
    } catch (e, st) {
      debugPrint('NotificationService.showTestNotification failed: $e\n$st');
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (Platform.isMacOS) {
      await _scheduleMacOS(id: id, title: title, body: body, at: at);
    } else {
      await _scheduleAlarm(id: id, title: title, body: body, at: at);
    }
  }

  static Future<void> _scheduleMacOS({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    try {
      final tzAt = tz.TZDateTime.from(at, tz.local);
      await _fln.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzAt,
        notificationDetails: const NotificationDetails(
          macOS: DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('NotificationService: macOS scheduled id=$id "$title" at $tzAt');
    } catch (e, st) {
      debugPrint('NotificationService._scheduleMacOS failed: $e\n$st');
    }
  }

  static Future<void> _scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    try {
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: id,
          dateTime: at,
          assetAudioPath: null,
          loopAudio: false,
          vibrate: false,
          warningNotificationOnKill: Platform.isIOS,
          androidFullScreenIntent: false,
          androidStopAlarmOnTermination: false,
          volumeSettings: VolumeSettings.fixed(volume: 0.0),
          notificationSettings: NotificationSettings(
            title: title,
            body: body,
            icon: 'ic_stat_notification',
          ),
        ),
      );
      debugPrint('NotificationService: alarm set id=$id "$title" at $at');
    } catch (e, st) {
      debugPrint('NotificationService._scheduleAlarm failed: $e\n$st');
    }
  }
}
