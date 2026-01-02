import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const String _passwordPrefix = 'ssh_password_';

  static Future<void> storePassword(String configId, String password) async {
    await _storage.write(key: '$_passwordPrefix$configId', value: password);
  }

  static Future<String?> getPassword(String configId) async {
    return await _storage.read(key: '$_passwordPrefix$configId');
  }

  static Future<void> deletePassword(String configId) async {
    await _storage.delete(key: '$_passwordPrefix$configId');
  }

  static Future<void> storePrivateKey(String configId, String keyContent) async {
    await _storage.write(key: 'ssh_key_$configId', value: keyContent);
  }

  static Future<String?> getPrivateKey(String configId) async {
    return await _storage.read(key: 'ssh_key_$configId');
  }

  static Future<void> deletePrivateKey(String configId) async {
    await _storage.delete(key: 'ssh_key_$configId');
  }
}
