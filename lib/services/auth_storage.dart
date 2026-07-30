import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedCredentials {
  final bool rememberMe;
  final String username;
  final String password;
  final String role;

  const SavedCredentials({
    required this.rememberMe,
    required this.username,
    required this.password,
    required this.role,
  });

  bool get canAutoLogin =>
      rememberMe && username.isNotEmpty && password.isNotEmpty;
}

abstract class SecureValueStore {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureValueStore implements SecureValueStore {
  final FlutterSecureStorage _storage;

  const FlutterSecureValueStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

class AuthStorage {
  static const _rememberKey = 'remember_me';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';
  static const _roleKey = 'role';

  final SecureValueStore _secureStore;

  const AuthStorage({
    SecureValueStore secureStore = const FlutterSecureValueStore(),
  }) : _secureStore = secureStore;

  Future<SavedCredentials> readCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberKey) ?? false;
    final username = prefs.getString(_usernameKey) ?? '';
    final role = prefs.getString(_roleKey) ?? '0';
    String password = '';
    try {
      password = await _secureStore.read(key: _passwordKey) ?? '';
    } catch (e) {
      // Secure storage may fail on keystore corruption / backup restore.
      // Clear the bad entry and treat as no saved password.
      try {
        await _secureStore.delete(key: _passwordKey);
      } catch (_) {}
      password = '';
    }

    return SavedCredentials(
      rememberMe: rememberMe,
      username: username,
      password: password,
      role: role,
    );
  }

  Future<void> saveCredentials({
    required bool rememberMe,
    required String username,
    required String password,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, rememberMe);

    if (!rememberMe) {
      await clearCredentials();
      return;
    }

    await prefs.setString(_usernameKey, username);
    await prefs.setString(_roleKey, role);
    await prefs.remove(_passwordKey);
    await _secureStore.write(key: _passwordKey, value: password);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, false);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_roleKey);
    await _secureStore.delete(key: _passwordKey);
  }
}
