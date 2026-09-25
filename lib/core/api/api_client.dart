import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int status;

  ApiException(this.message, this.status);

  @override
  String toString() => message;
}

class ApiClient {
  // Backend local
  static const String baseUrl = 'http://localhost:8087';

  String? token;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
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

      throw ApiException(
        'No se pudo conectar con el servidor.',
        0,
      );
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

      throw ApiException(
        'No se pudo conectar con el servidor.',
        0,
      );
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

      throw ApiException(
        'No se pudo conectar con el servidor.',
        0,
      );
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

      throw ApiException(
        'No se pudo conectar con el servidor.',
        0,
      );
    }
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