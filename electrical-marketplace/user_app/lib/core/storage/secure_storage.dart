import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'user_token';
  static const _keyUserId = 'user_id';
  static const _keyPhone = 'user_phone';
  static const _keyName = 'user_name';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> saveUserId(String id) =>
      _storage.write(key: _keyUserId, value: id);

  static Future<String?> getUserId() => _storage.read(key: _keyUserId);

  static Future<void> savePhone(String phone) =>
      _storage.write(key: _keyPhone, value: phone);

  static Future<String?> getPhone() => _storage.read(key: _keyPhone);

  static Future<void> saveName(String name) =>
      _storage.write(key: _keyName, value: name);

  static Future<String?> getName() => _storage.read(key: _keyName);

  static Future<void> clearAll() => _storage.deleteAll();

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
