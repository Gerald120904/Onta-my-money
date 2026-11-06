import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int status;
  final bool isNetworkError;

  ApiException(this.message, this.status, {this.isNetworkError = false});

  @override
  String toString() => message;
}

class ApiConfig {
  static const String productionUrl =
      'https://onta-my-money-api.gerald.prod.page';
  static const String _envUrl = String.fromEnvironment('API_URL');
  static const String _envPort =
      String.fromEnvironment('API_PORT', defaultValue: '8080');

  static String get baseUrl => resolveBaseUrl(
        isRelease: kReleaseMode,
        isWeb: kIsWeb,
        isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
        configuredUrl: _envUrl,
        port: _envPort,
      );

  @visibleForTesting
  static String resolveBaseUrl({
    required bool isRelease,
    required bool isWeb,
    required bool isAndroid,
    required String configuredUrl,
    String port = '8080',
  }) {
    if (isRelease) {
      if (configuredUrl.isNotEmpty && configuredUrl != productionUrl) {
        throw StateError('La API de producción debe usar $productionUrl');
      }
      return productionUrl;
    }
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (isWeb) {
      return 'http://localhost:$port';
    }

    if (isAndroid) {
      return 'http://10.0.2.2:$port';
    }

    return 'http://localhost:$port';
  }
}

class ApiClient {
  final http.Client _http;
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  String? token;
  String? refreshToken;
  String? deviceId;
  Future<void> Function(String accessToken, String? refreshToken)? onTokensRotated;
  Future<bool>? _refreshInFlight;

  String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
        if (deviceId != null && deviceId!.isNotEmpty) 'X-Device-Id': deviceId!,
      };

  Future<dynamic> get(String path) async {
    return _request(() => _http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15)));
  }

  Future<dynamic> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    return _request(() => _http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15)),
        allowRefresh: path == '/api/auth/logout-all' ||
            !path.startsWith('/api/auth/'));
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _request(() => _http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15)));
  }

  Future<dynamic> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    return _request(() => _http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15)));
  }

  Future<dynamic> delete(String path) async {
    return _request(() => _http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15)));
  }

  Future<dynamic> _request(Future<http.Response> Function() send,
      {bool allowRefresh = true}) async {
    try {
      final usedToken = token;
      var response = await send();
      if (response.statusCode == 401 && allowRefresh &&
          refreshToken != null && refreshToken!.isNotEmpty) {
        if (token != usedToken || await _refreshSession()) {
          response = await send();
        }
      }
      return _decode(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw _wrapNetworkError(error);
    }
  }

  Future<bool> _refreshSession() {
    if (_refreshInFlight != null) return _refreshInFlight!;
    final operation = _rotateTokens();
    _refreshInFlight = operation;
    operation.then((_) => _refreshInFlight = null,
        onError: (Object _, StackTrace __) => _refreshInFlight = null);
    return operation;
  }

  Future<bool> _rotateTokens() async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return false;
      }
      final data = jsonDecode(response.body);
      if (data is! Map || data['token'] is! String ||
          data['refresh_token'] is! String) {
        return false;
      }
      final nextToken = data['token'] as String;
      final nextRefresh = data['refresh_token'] as String;
      await onTokensRotated?.call(nextToken, nextRefresh);
      token = nextToken;
      refreshToken = nextRefresh;
      return true;
    } catch (_) {
      return false;
    }
  }

  ApiException _wrapNetworkError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException) {
      return ApiException(
        'Sin conexión con el servidor. Modo offline activo.',
        0,
        isNetworkError: true,
      );
    }
    return ApiException(
      'No se pudo conectar con el servidor ($error)',
      0,
      isNetworkError: true,
    );
  }

  dynamic _decode(http.Response response) {
    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (response.statusCode >= 400) {
      String message = 'Error en la solicitud.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }

      throw ApiException(
        message,
        response.statusCode,
      );
    }

    return data;
  }
}
