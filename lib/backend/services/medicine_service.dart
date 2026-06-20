import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../models/history_entry.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/user_repository.dart';
import '../database/local_database.dart';
import 'dose_window.dart';

class MedicineResult {
  final bool success;
  final String? error;
  final Medicine? medicine;

  const MedicineResult({required this.success, this.error, this.medicine});
}

class MedicineService {
  final MedicineRepository _medRepo = MedicineRepository();
  final HistoryRepository _histRepo = HistoryRepository();
  final UserRepository _userRepo = UserRepository();

  Future<List<Medicine>> getMedicines() => _medRepo.getAll();

  Future<MedicineResult> addMedicine({
    required String name,
    required String dose,
    required String time,
    required List<String> repeatDays,
    MedicineType type = MedicineType.tablet,
    String? notes,
    int colorIndex = 0,
  }) async {
    if (name.trim().isEmpty) {
      return const MedicineResult(success: false, error: 'Medicine name is required');
    }

    final exists = await _medRepo.exists(name.trim(), time);
    if (exists) {
      return const MedicineResult(
          success: false, error: 'A medicine with this name and time already exists');
    }

    final medicine = Medicine(
      id: Medicine.generateId(),
      name: name.trim(),
      dose: dose.trim(),
      time: time,
      repeatDays: repeatDays,
      type: type,
      notes: notes,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );

    await _medRepo.save(medicine);
    return MedicineResult(success: true, medicine: medicine);
  }

  Future<MedicineResult> updateMedicine(
    String id, {
    required String name,
    required String dose,
    required String time,
    required List<String> repeatDays,
    MedicineType type = MedicineType.tablet,
    String? notes,
    int colorIndex = 0,
  }) async {
    if (name.trim().isEmpty) {
      return const MedicineResult(success: false, error: 'Medicine name is required');
    }

    final existing = await _medRepo.getById(id);
    if (existing == null) {
      return const MedicineResult(success: false, error: 'Medicine not found');
    }

    if (existing.name.toLowerCase() != name.trim().toLowerCase() ||
        existing.time != time) {
      final exists = await _medRepo.exists(name.trim(), time);
      if (exists) {
        return const MedicineResult(
            success: false,
            error: 'A medicine with this name and time already exists');
      }
    }

    final updated = Medicine(
      id: existing.id,
      name: name.trim(),
      dose: dose.trim(),
      time: time,
      repeatDays: repeatDays,
      status: existing.status,
      type: type,
      notes: notes,
      colorIndex: colorIndex,
      isActive: existing.isActive,
      createdAt: existing.createdAt,
    );

    await _medRepo.save(updated);
    return MedicineResult(success: true, medicine: updated);
  }

  Future<MedicineResult> updateStatus(
      String medicineId, MedicineStatus status) async {
    try {
      final all = await _medRepo.getAll();
      final med = all.firstWhereOrNull((m) => m.id == medicineId);
      if (med == null) {
        return const MedicineResult(success: false, error: 'Medicine not found');
      }
      final updated = med.copyWith(status: status);
      await _medRepo.save(updated);

      await _histRepo.addFromMedicine(med, status);

      if (status == MedicineStatus.taken || status == MedicineStatus.takenLate) {
        await _userRepo.updateStats(takenDelta: 1);
      } else if (status == MedicineStatus.missed) {
        await _userRepo.updateStats(missedDelta: 1);
      }

      return MedicineResult(success: true, medicine: updated);
    } catch (e) {
      return MedicineResult(success: false, error: e.toString());
    }
  }

  Future<void> deleteMedicine(String id) async {
    await _medRepo.delete(id);
    await _histRepo.deleteByMedicineId(id);
  }

  Future<List<HistoryEntry>> getHistory() => _histRepo.getAll();

  Future<Map<DateTime, List<HistoryEntry>>> getHistoryGrouped() =>
      _histRepo.getGroupedByDate();

  Future<void> resetDailyStatuses() async {
    final all = await _medRepo.getAll();
    final reset = all.map((m) => m.copyWith(status: MedicineStatus.pending)).toList();
    await _medRepo.saveAll(reset);
  }

  Future<void> autoMarkOverdue() async {
    final all = await _medRepo.getAll();
    final now = DateTime.now();
    for (final med in all) {
      if (!med.isPending) continue;
      final scheduled = DoseWindowHelper.parseScheduledToday(med.time);
      if (scheduled == null) continue;
      // TEST threshold — restore to > 360 after testing
      if (now.difference(scheduled).inMinutes > 2) {
        final updated = med.copyWith(status: MedicineStatus.missed);
        await _medRepo.save(updated);
        await _histRepo.addFromMedicine(med, MedicineStatus.missed);
        await _userRepo.updateStats(missedDelta: 1);
      }
    }
  }

  Future<bool> resetForNewDay() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastReset = await LocalDatabase.instance.getLastResetDate();
    if (lastReset == todayStr) return false;
    await resetDailyStatuses();
    await LocalDatabase.instance.setLastResetDate(todayStr);
    return true;
  }

  Future<void> init() async {}
}
