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
  String? token;
  String? deviceId;

  String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
        if (deviceId != null && deviceId!.isNotEmpty) 'X-Device-Id': deviceId!,
      };

  Future<dynamic> get(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      return _decode(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _wrapNetworkError(e);
    }
  }

  Future<dynamic> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15));

      return _decode(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _wrapNetworkError(e);
    }
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _decode(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _wrapNetworkError(e);
    }
  }

  Future<dynamic> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15));

      return _decode(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _wrapNetworkError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      return _decode(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _wrapNetworkError(e);
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
