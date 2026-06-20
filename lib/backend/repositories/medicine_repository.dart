import '../database/local_database.dart';
import '../models/medicine.dart';

class MedicineRepository {
  final LocalDatabase _db = LocalDatabase.instance;

  Future<List<Medicine>> getAll() async {
    final raw = await _db.getMedicines();
    return raw.map(Medicine.fromJson).toList();
  }

  Future<void> save(Medicine medicine) async {
    await _db.saveMedicine(medicine.toJson());
  }

  Future<void> saveAll(List<Medicine> medicines) async {
    await _db.saveMedicines(medicines.map((m) => m.toJson()).toList());
  }

  Future<void> delete(String id) async {
    await _db.deleteMedicine(id);
  }

  Future<Medicine?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatus(String id, MedicineStatus status) async {
    final all = await getAll();
    final idx = all.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final updated = all[idx].copyWith(status: status);
      await save(updated);
    }
  }

  Future<bool> exists(String name, String time) async {
    final all = await getAll();
    return all.any(
      (m) =>
          m.name.toLowerCase() == name.toLowerCase() &&
          m.time == time &&
          m.isActive,
    );
  }

}

