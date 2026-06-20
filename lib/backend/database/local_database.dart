import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabase {
  static const String _userKey = 'db_user';
  static const String _loggedInKey = 'db_logged_in';
  static const String _schemaVersionKey = 'db_schema_version';
  // Bump this when a breaking change requires wiping stored data.
  static const int _currentSchemaVersion = 2;

  String? _currentUserEmail;

  static LocalDatabase? _instance;
  SharedPreferences? _prefs;

  LocalDatabase._();

  static LocalDatabase get instance {
    _instance ??= LocalDatabase._();
    return _instance!;
  }

  void setCurrentUserEmail(String? email) {
    _currentUserEmail = email;
  }

  // Base64-url encode the email to avoid key collisions between e.g.
  // "a.b@c.com" and "a_b_c_com" that the old underscore-replace caused.
  String _userTag() {
    if (_currentUserEmail == null) return '';
    final bytes = utf8.encode(_currentUserEmail!.toLowerCase().trim());
    return '_${base64Url.encode(bytes).replaceAll('=', '')}';
  }

  String _emailKey(String email) {
    final bytes = utf8.encode(email.toLowerCase().trim());
    return 'db_user_${base64Url.encode(bytes).replaceAll('=', '')}';
  }

  String get _medicinesKey => 'db_medicines${_userTag()}';
  String get _historyKey => 'db_history${_userTag()}';
  String get _lastResetKey => 'db_last_reset${_userTag()}';
  String get _settingsKey => 'db_settings${_userTag()}';
  String get _onboardingKey => 'db_onboarding_done${_userTag()}';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _runMigrations();
  }

  // Wipes all stored data when the schema version increases, so stale or
  // insecure data (e.g. plain-text passwords) is never carried forward.
  Future<void> _runMigrations() async {
    final version = _p.getInt(_schemaVersionKey) ?? 0;
    if (version < _currentSchemaVersion) {
      await _p.clear();
      await _p.setInt(_schemaVersionKey, _currentSchemaVersion);
    }
  }

  SharedPreferences get _p {
    if (_prefs == null) throw StateError('LocalDatabase not initialized');
    return _prefs!;
  }

  // ─── Generic CRUD ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAll(String key) async {
    final raw = _p.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveAll(String key, List<Map<String, dynamic>> data) async {
    await _p.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getById(String key, String id) async {
    final all = await getAll(key);
    try {
      return all.firstWhere((e) => e['id'] == id);
    } on StateError {
      return null;
    }
  }

  Future<void> upsert(String key, Map<String, dynamic> item) async {
    final all = await getAll(key);
    final idx = all.indexWhere((e) => e['id'] == item['id']);
    if (idx >= 0) {
      all[idx] = item;
    } else {
      all.add(item);
    }
    await saveAll(key, all);
  }

  Future<void> delete(String key, String id) async {
    final all = await getAll(key);
    all.removeWhere((e) => e['id'] == id);
    await saveAll(key, all);
  }

  Future<void> clear(String key) async {
    await _p.remove(key);
  }

  // ─── Typed accessors ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMedicines() => getAll(_medicinesKey);
  Future<void> saveMedicine(Map<String, dynamic> m) => upsert(_medicinesKey, m);
  Future<void> deleteMedicine(String id) => delete(_medicinesKey, id);
  Future<void> saveMedicines(List<Map<String, dynamic>> list) =>
      saveAll(_medicinesKey, list);

  Future<List<Map<String, dynamic>>> getHistory() => getAll(_historyKey);
  Future<void> saveHistoryEntry(Map<String, dynamic> h) =>
      upsert(_historyKey, h);
  Future<void> saveHistory(List<Map<String, dynamic>> list) =>
      saveAll(_historyKey, list);

  Future<Map<String, dynamic>?> getUser() async {
    final raw = _p.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _p.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final raw = _p.getString(_emailKey(email));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveUserForEmail(String email, Map<String, dynamic> user) async {
    await _p.setString(_emailKey(email), jsonEncode(user));
  }

  Future<void> clearCurrentUserSession() async {
    await _p.remove(_userKey);
  }

  Future<Map<String, dynamic>> getSettings() async {
    final raw = _p.getString(_settingsKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _p.setString(_settingsKey, jsonEncode(settings));
  }

  Future<bool> isOnboardingDone() async => _p.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingDone() async =>
      _p.setBool(_onboardingKey, true);

  Future<bool> isLoggedIn() async => _p.getBool(_loggedInKey) ?? false;
  Future<void> setLoggedIn(bool value) async =>
      _p.setBool(_loggedInKey, value);

  Future<String?> getLastResetDate() async => _p.getString(_lastResetKey);
  Future<void> setLastResetDate(String date) async =>
      _p.setString(_lastResetKey, date);

  Future<void> clearAll() async {
    await _p.remove(_medicinesKey);
    await _p.remove(_historyKey);
    await _p.remove(_settingsKey);
    await _p.remove(_lastResetKey);
    await _p.remove(_onboardingKey);
    await _p.remove(_userKey);
    await _p.setBool(_loggedInKey, false);
  }
}
