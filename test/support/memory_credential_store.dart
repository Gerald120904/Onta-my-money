import 'package:donde_se_fue_mi_plata/services/auth/credential_store.dart';

class MemoryCredentialStore implements CredentialStore {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> save(String accessToken, String? refreshToken) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}
