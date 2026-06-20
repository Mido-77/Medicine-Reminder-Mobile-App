import '../models/medicine.dart';

enum DoseWindow { beforeWindow, inWindow, lateWindow, missed }

class DoseWindowHelper {
  // ── TEST values ─────────────────────────────────────────────────────────────
  static const Duration _earlyWindow = Duration(seconds: 30);
  static const Duration _onTimeWindow = Duration(seconds: 30);
  static const Duration _missedWindow = Duration(minutes: 2);
  // ── NORMAL values (restore after testing) ───────────────────────────────────
  // static const Duration _earlyWindow  = Duration(hours: 1);
  // static const Duration _onTimeWindow = Duration(hours: 1);
  // static const Duration _missedWindow = Duration(hours: 6);

  static DateTime? parseScheduledToday(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static DoseWindow compute(String timeStr) {
    final scheduled = parseScheduledToday(timeStr);
    if (scheduled == null) return DoseWindow.inWindow;
    final diff = DateTime.now().difference(scheduled);
    if (diff < -_earlyWindow) return DoseWindow.beforeWindow;
    if (diff <= _onTimeWindow) return DoseWindow.inWindow;
    if (diff <= _missedWindow) return DoseWindow.lateWindow;
    return DoseWindow.missed;
  }

  static Duration timeUntilWindowOpens(String timeStr) {
    final scheduled = parseScheduledToday(timeStr);
    if (scheduled == null) return Duration.zero;
    final windowOpens = scheduled.subtract(_earlyWindow);
    final diff = windowOpens.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  static MedicineStatus autoStatus(String timeStr) {
    final scheduled = parseScheduledToday(timeStr);
    if (scheduled == null) return MedicineStatus.taken;
    final diff = DateTime.now().difference(scheduled);
    return diff <= _onTimeWindow ? MedicineStatus.taken : MedicineStatus.takenLate;
  }
}
