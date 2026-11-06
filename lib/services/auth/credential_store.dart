import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class CredentialStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> save(String accessToken, String? refreshToken);
  Future<void> clear();
}

class SecureCredentialStore implements CredentialStore {
  final FlutterSecureStorage storage;

  SecureCredentialStore({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readAccessToken() => storage.read(key: 'onta_access_token');

  @override
  Future<String?> readRefreshToken() => storage.read(key: 'onta_refresh_token');

  @override
  Future<void> save(String accessToken, String? refreshToken) async {
    await storage.write(key: 'onta_access_token', value: accessToken);
    if (refreshToken == null) {
      await storage.delete(key: 'onta_refresh_token');
    } else {
      await storage.write(key: 'onta_refresh_token', value: refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    await storage.delete(key: 'onta_access_token');
    await storage.delete(key: 'onta_refresh_token');
  }
}
