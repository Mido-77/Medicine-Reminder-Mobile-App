import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'backend/database/local_database.dart';
import 'backend/models/medicine.dart';
import 'backend/models/history_entry.dart';
import 'backend/models/user.dart';
import 'backend/services/auth_service.dart';
import 'backend/services/medicine_service.dart';
import 'backend/services/notification_service.dart';
import 'backend/services/dose_window.dart';
import 'backend/repositories/user_repository.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final MedicineService _medicineService = MedicineService();
  final UserRepository _userRepo = UserRepository();

  List<Medicine> _medicines = [];
  List<HistoryEntry> _history = [];
  User _user = User.defaultUser;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _onboardingDone = false;
  String? _error;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _reminderSound = 'Default';
  bool _exactAlarmGranted = true;

  bool get exactAlarmGranted => _exactAlarmGranted;

  List<Medicine> get medicines => List.unmodifiable(_medicines);
  List<HistoryEntry> get history => List.unmodifiable(_history);
  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get onboardingDone => _onboardingDone;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  String get reminderSound => _reminderSound;

  int get takenCount =>
      _medicines.where((m) => m.isTaken || m.isTakenLate).length;
  int get totalCount => _medicines.length;
  double get progress => totalCount == 0 ? 0 : takenCount / totalCount;
  bool get hasMissedDose => _medicines.any((m) => m.isMissed);
  List<Medicine> get pendingMedicines =>
      _medicines.where((m) => m.isPending).toList();
  List<Medicine> get completedMedicines =>
      _medicines.where((m) => m.isDone).toList();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await LocalDatabase.instance.init();
      await NotificationService.instance.init();
      _exactAlarmGranted = await NotificationService.instance.canScheduleExactAlarms();
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        final currentUser = await _userRepo.getUser();
        if (currentUser.email.isNotEmpty) {
          LocalDatabase.instance.setCurrentUserEmail(currentUser.email);
        }
        await _medicineService.resetForNewDay();
        await _loadData();
        await _medicineService.autoMarkOverdue();
        _medicines = await _medicineService.getMedicines();
        _history = await _medicineService.getHistory();
        if (_notificationsEnabled) {
          await NotificationService.instance.scheduleAll(_medicines);
        }
      }
      // Read onboarding status after email is set so we get the per-user key.
      _onboardingDone = await LocalDatabase.instance.isOnboardingDone();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadData() async {
    _medicines = await _medicineService.getMedicines();
    _history = await _medicineService.getHistory();
    _user = await _userRepo.getUser();
    final settings = await LocalDatabase.instance.getSettings();
    _notificationsEnabled = settings['notifications'] as bool? ?? true;
    _darkMode = settings['darkMode'] as bool? ?? false;
    _reminderSound = settings['reminderSound'] as String? ?? 'Default';
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.login(email, password);
      if (result.success) {
        _isLoggedIn = true;
        await NotificationService.instance.cancelAll();
        LocalDatabase.instance.setCurrentUserEmail(email.trim());
        await _loadData();
        _onboardingDone = await LocalDatabase.instance.isOnboardingDone();
        if (_notificationsEnabled) {
          await NotificationService.instance.scheduleAll(_medicines);
        }
        return true;
      }
      _error = result.error;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.signup(name, email, password);
      if (result.success) {
        _isLoggedIn = true;
        LocalDatabase.instance.setCurrentUserEmail(email.trim());
        await _loadData();
        _onboardingDone = await LocalDatabase.instance.isOnboardingDone();
        return true;
      }
      _error = result.error;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await NotificationService.instance.cancelAll();
    await LocalDatabase.instance.clearCurrentUserSession();
    await _authService.logout();
    LocalDatabase.instance.setCurrentUserEmail(null);
    _isLoggedIn = false;
    _medicines = [];
    _history = [];
    _user = User.defaultUser;
    _darkMode = false;
    _notificationsEnabled = true;
    _reminderSound = 'Default';
    _onboardingDone = false;
    notifyListeners();
  }

  Future<bool> addMedicine({
    required String name,
    required String dose,
    required String time,
    required List<String> repeatDays,
    MedicineType type = MedicineType.tablet,
    String? notes,
    int colorIndex = 0,
  }) async {
    _error = null;
    final result = await _medicineService.addMedicine(
      name: name,
      dose: dose,
      time: time,
      repeatDays: repeatDays,
      type: type,
      notes: notes,
      colorIndex: colorIndex,
    );
    if (result.success) {
      _medicines = await _medicineService.getMedicines();
      if (_notificationsEnabled && result.medicine != null) {
        await NotificationService.instance.scheduleForMedicine(result.medicine!);
      }
      notifyListeners();
      return true;
    }
    _error = result.error;
    notifyListeners();
    return false;
  }

  Future<bool> updateMedicine(
    String id, {
    required String name,
    required String dose,
    required String time,
    required List<String> repeatDays,
    MedicineType type = MedicineType.tablet,
    String? notes,
    int colorIndex = 0,
  }) async {
    _error = null;
    final result = await _medicineService.updateMedicine(
      id,
      name: name,
      dose: dose,
      time: time,
      repeatDays: repeatDays,
      type: type,
      notes: notes,
      colorIndex: colorIndex,
    );
    if (result.success) {
      _medicines = await _medicineService.getMedicines();
      if (_notificationsEnabled && result.medicine != null) {
        await NotificationService.instance.scheduleForMedicine(result.medicine!);
      }
      notifyListeners();
      return true;
    }
    _error = result.error;
    notifyListeners();
    return false;
  }

  Future<void> takeMedicine(String medicineId) async {
    _error = null;
    final med = _medicines.firstWhereOrNull((m) => m.id == medicineId);
    if (med == null) return;
    final status = DoseWindowHelper.autoStatus(med.time);
    await NotificationService.instance.cancelForMedicine(medicineId);
    await _medicineService.updateStatus(medicineId, status);
    _medicines = await _medicineService.getMedicines();
    _history = await _medicineService.getHistory();
    _user = await _userRepo.getUser();
    notifyListeners();
  }

  Future<void> updateMedicineStatus(String id, MedicineStatus status) async {
    _error = null;
    await _medicineService.updateStatus(id, status);
    _medicines = await _medicineService.getMedicines();
    _history = await _medicineService.getHistory();
    _user = await _userRepo.getUser();
    notifyListeners();
  }

  Future<void> deleteMedicine(String id) async {
    _error = null;
    await NotificationService.instance.cancelForMedicine(id);
    await _medicineService.deleteMedicine(id);
    _medicines = await _medicineService.getMedicines();
    _history = await _medicineService.getHistory();
    notifyListeners();
  }

  Future<void> updateUser(User updated) async {
    _error = null;
    _user = updated;
    await _userRepo.saveUser(updated);
    notifyListeners();
  }

  Future<void> requestExactAlarmPermission() async {
    _error = null;
    await NotificationService.instance.requestExactAlarmPermission();
    _exactAlarmGranted = await NotificationService.instance.canScheduleExactAlarms();
    if (_exactAlarmGranted && _notificationsEnabled) {
      await NotificationService.instance.scheduleAll(_medicines);
    }
    notifyListeners();
  }

  Future<void> setOnboardingDone() async {
    _error = null;
    await LocalDatabase.instance.setOnboardingDone();
    _onboardingDone = true;
    notifyListeners();
  }

  Future<void> updateSettings({
    bool? notifications,
    bool? darkMode,
    String? reminderSound,
  }) async {
    _error = null;
    if (notifications != null) {
      // Perform the async operation first; only update the flag on success.
      if (!notifications) {
        await NotificationService.instance.cancelAll();
      } else {
        await NotificationService.instance.scheduleAll(_medicines);
      }
      _notificationsEnabled = notifications;
    }
    if (darkMode != null) _darkMode = darkMode;
    if (reminderSound != null) _reminderSound = reminderSound;
    await LocalDatabase.instance.saveSettings({
      'notifications': _notificationsEnabled,
      'darkMode': _darkMode,
      'reminderSound': _reminderSound,
    });
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await NotificationService.instance.cancelAll();
    await LocalDatabase.instance.clearAll();
    _medicines = [];
    _history = [];
    _darkMode = false;
    _notificationsEnabled = true;
    _reminderSound = 'Default';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    _medicines = await _medicineService.getMedicines();
    _history = await _medicineService.getHistory();
    _user = await _userRepo.getUser();
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in widget tree');
    return scope!.notifier!;
  }
}
