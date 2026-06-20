import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/medicine.dart';
import 'dose_window.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationDetails(
    'medicine_reminders',
    'Medicine Reminders',
    channelDescription: 'Reminders to take your medicine on time',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  static const _details = NotificationDetails(android: _androidChannel);

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;

    // Request POST_NOTIFICATIONS permission (Android 13+).
    await _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('NotificationService: requestNotificationsPermission error: $e');
    }
  }

  /// Call this from a screen context after the user is logged in.
  /// On Android 12+, SCHEDULE_EXACT_ALARM must be granted by the user in
  /// Settings. This opens that settings page if the permission is missing.
  Future<void> requestExactAlarmPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('NotificationService: requestExactAlarmsPermission error: $e');
    }
  }

  /// Returns true if exact alarms can be scheduled (Android 12+ gate).
  Future<bool> canScheduleExactAlarms() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> scheduleForMedicine(Medicine medicine) async {
    if (!_initialized) await init();
    await cancelForMedicine(medicine.id);

    final scheduled = DoseWindowHelper.parseScheduledToday(medicine.time);
    if (scheduled == null) return;

    final now = DateTime.now();
    // TEST values — restore to Duration(hours: 1) and Duration(hours: 6) after testing
    final windowOpen = scheduled.subtract(const Duration(seconds: 30));
    final missedAt = scheduled.add(const Duration(minutes: 2));

    if (windowOpen.isAfter(now)) {
      await _schedule(
        _notifId(medicine.id, 0),
        'Take ${medicine.name} soon',
        'Your window to take ${medicine.name} opens now. You have 2.5 minutes.',
        windowOpen,
      );
    }

    if (scheduled.isAfter(now)) {
      await _schedule(
        _notifId(medicine.id, 1),
        'Time to take ${medicine.name}',
        medicine.dose.isNotEmpty
            ? 'Take your ${medicine.dose} of ${medicine.name} now.'
            : 'Take ${medicine.name} now.',
        scheduled,
      );
    }

    if (missedAt.isAfter(now)) {
      await _schedule(
        _notifId(medicine.id, 2),
        '${medicine.name} — dose missed',
        'You missed your scheduled dose of ${medicine.name}.',
        missedAt,
      );
    }
  }

  Future<void> _schedule(
      int id, String title, String body, DateTime when) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('NotificationService: scheduled "$title" for $when');
    } catch (e) {
      debugPrint('NotificationService: failed to schedule "$title": $e');
      // Fallback to inexact alarm if exact alarm permission is denied.
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(when, tz.local),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('NotificationService: scheduled (inexact) "$title" for $when');
      } catch (e2) {
        debugPrint('NotificationService: inexact fallback also failed: $e2');
      }
    }
  }

  Future<void> cancelForMedicine(String medicineId) async {
    await _plugin.cancel(_notifId(medicineId, 0));
    await _plugin.cancel(_notifId(medicineId, 1));
    await _plugin.cancel(_notifId(medicineId, 2));
  }

  Future<void> scheduleAll(List<Medicine> medicines) async {
    if (!_initialized) await init();
    for (final med in medicines) {
      if (med.isActive && med.isPending) {
        await scheduleForMedicine(med);
      } else {
        // Always cancel for inactive or already-done medicines so stale
        // notifications don't keep firing after a medicine is deactivated.
        await cancelForMedicine(med.id);
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Use a wider slot range (699M) so collision probability is negligible even
  // with many medicines. Multiply by 3 (one slot per notification type) and
  // stay within Android's signed 32-bit notification ID limit (~2.1B).
  int _notifId(String medicineId, int offset) =>
      (medicineId.hashCode.abs() % 699999999) * 3 + offset;
}
