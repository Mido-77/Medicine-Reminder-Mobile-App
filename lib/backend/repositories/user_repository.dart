import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../database/local_database.dart';
import '../models/user.dart';

class UserRepository {
  final LocalDatabase _db = LocalDatabase.instance;

  // One-way SHA-256 hash. Passwords are never stored or compared in plain text.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<User> getUser() async {
    final json = await _db.getUser();
    if (json == null) return User.defaultUser;
    return User.fromJson(json);
  }

  Future<void> saveUser(User user) async {
    await _db.saveUser(user.toJson());
    await _db.saveUserForEmail(user.email, user.toJson());
  }

  Future<void> updateStats({int? takenDelta, int? missedDelta}) async {
    final user = await getUser();
    final updated = user.copyWith(
      totalTaken: user.totalTaken + (takenDelta ?? 0),
      totalMissed: user.totalMissed + (missedDelta ?? 0),
    );
    await saveUser(updated);
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.length < 4) return false;
    final userJson = await _db.getUserByEmail(email);
    if (userJson == null) return false;
    final stored = User.fromJson(userJson);
    if (stored.password.isNotEmpty && stored.password != _hashPassword(password)) {
      return false;
    }
    await _db.saveUser(stored.toJson());
    await _db.setLoggedIn(true);
    return true;
  }

  Future<bool> signup(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.length < 4) return false;
    final user = User(
      id: 'user_${const Uuid().v4()}',
      name: name,
      email: email,
      password: _hashPassword(password),
      createdAt: DateTime.now(),
    );
    await saveUser(user);
    await _db.setLoggedIn(true);
    return true;
  }

  Future<void> logout() async {
    await _db.setLoggedIn(false);
  }

  Future<bool> isLoggedIn() => _db.isLoggedIn();

  Future<void> changePassword(String current, String newPass) async {
    if (newPass.length < 6) throw Exception('Password must be at least 6 characters');
    final user = await getUser();
    if (user.password.isNotEmpty && user.password != _hashPassword(current)) {
      throw Exception('Current password is incorrect');
    }
    await saveUser(user.copyWith(password: _hashPassword(newPass)));
  }
}
