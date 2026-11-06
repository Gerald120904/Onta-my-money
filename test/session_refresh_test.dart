import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:donde_se_fue_mi_plata/core/api/api_client.dart';

void main() {
  test('HTTP 401 renueva tokens una vez y reintenta la petición', () async {
    var refreshCalls = 0;
    var dataCalls = 0;
    final client = ApiClient(client: MockClient((request) async {
      if (request.url.path == '/api/auth/refresh') {
        refreshCalls++;
        expect(jsonDecode(request.body)['refresh_token'], 'old-refresh');
        return http.Response(jsonEncode({
          'token': 'new-access', 'refresh_token': 'new-refresh',
        }), 200);
      }
      dataCalls++;
      if (request.headers['Authorization'] == 'Bearer old-access') {
        return http.Response('{}', 401);
      }
      expect(request.headers['Authorization'], 'Bearer new-access');
      return http.Response('{"ok":true}', 200);
    }));
    client.token = 'old-access';
    client.refreshToken = 'old-refresh';
    String? storedAccess;
    String? storedRefresh;
    client.onTokensRotated = (access, refresh) async {
      storedAccess = access;
      storedRefresh = refresh;
    };

    expect((await client.get('/api/accounts'))['ok'], true);
    expect(refreshCalls, 1);
    expect(dataCalls, 2);
    expect(storedAccess, 'new-access');
    expect(storedRefresh, 'new-refresh');
  });

  test('Refresh rechazado no crea un ciclo de reintentos', () async {
    var calls = 0;
    final client = ApiClient(client: MockClient((request) async {
      calls++;
      return http.Response('{"message":"expired"}', 401);
    }));
    client.token = 'expired-access';
    client.refreshToken = 'expired-refresh';
    await expectLater(client.get('/api/accounts'), throwsA(isA<ApiException>()));
    expect(calls, 2);
  });
}
