import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> save(String key, String value) async {
    final cleanValue = value.trim().replaceAll('\n', '').replaceAll('\r', '');
    await _storage.write(key: key, value: cleanValue);
  }

  static Future<String?> read(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return value.trim().replaceAll('\n', '').replaceAll('\r', '');
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
