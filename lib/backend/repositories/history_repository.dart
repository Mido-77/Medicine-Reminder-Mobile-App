import '../database/local_database.dart';
import '../models/history_entry.dart';
import '../models/medicine.dart';

class HistoryRepository {
  final LocalDatabase _db = LocalDatabase.instance;

  Future<List<HistoryEntry>> getAll() async {
    final raw = await _db.getHistory();
    return raw.map(HistoryEntry.fromJson).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  Future<void> add(HistoryEntry entry) async {
    await _db.saveHistoryEntry(entry.toJson());
  }

  Future<void> addFromMedicine(Medicine medicine, MedicineStatus status) async {
    final entry = HistoryEntry(
      id: HistoryEntry.generateId(),
      medicineId: medicine.id,
      medicineName: medicine.name,
      dose: medicine.dose,
      time: medicine.time,
      status: status,
      occurredAt: DateTime.now(),
    );
    await add(entry);
  }

  Future<List<HistoryEntry>> getToday() async {
    final all = await getAll();
    final today = DateTime.now();
    return all.where((e) {
      return e.occurredAt.year == today.year &&
          e.occurredAt.month == today.month &&
          e.occurredAt.day == today.day;
    }).toList();
  }

  Future<List<HistoryEntry>> getForDateRange(
      DateTime start, DateTime end) async {
    final all = await getAll();
    return all.where((e) {
      return e.occurredAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.occurredAt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Future<Map<DateTime, List<HistoryEntry>>> getGroupedByDate() async {
    final all = await getAll();
    final Map<DateTime, List<HistoryEntry>> grouped = {};
    for (final entry in all) {
      final date = DateTime(
        entry.occurredAt.year,
        entry.occurredAt.month,
        entry.occurredAt.day,
      );
      grouped.putIfAbsent(date, () => []).add(entry);
    }
    return grouped;
  }

  Future<void> deleteByMedicineId(String medicineId) async {
    final all = await getAll();
    final filtered = all.where((e) => e.medicineId != medicineId).toList();
    await _db.saveHistory(filtered.map((e) => e.toJson()).toList());
  }

}
