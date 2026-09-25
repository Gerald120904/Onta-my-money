import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  String? token;

  // =========================================================
  // URL DEL BACKEND
  // =========================================================
  //
  // Web:
  // localhost apunta a la computadora.
  //
  // Android Emulator:
  // 10.0.2.2 apunta a la computadora anfitriona.
  // =========================================================

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8087';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8087';
    }

    return 'http://localhost:8087';
  }

  // =========================================================
  // HEADERS
  // =========================================================

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // =========================================================
  // GET
  // =========================================================

  Future<dynamic> get(String path) async {
    final response = await http.get(
      _buildUri(path),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // POST
  // =========================================================

  Future<dynamic> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await http.post(
      _buildUri(path),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // PUT
  // =========================================================

  Future<dynamic> put(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await http.put(
      _buildUri(path),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      _buildUri(path),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CONSTRUIR URL
  // =========================================================

  Uri _buildUri(String path) {
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return Uri.parse(path);
    }

    final normalizedPath =
        path.startsWith('/') ? path : '/$path';

    return Uri.parse(
      '$baseUrl$normalizedPath',
    );
  }

  // =========================================================
  // PROCESAR RESPUESTA
  // =========================================================

  dynamic _handleResponse(
    http.Response response,
  ) {
    final statusCode = response.statusCode;

    final body = utf8.decode(
      response.bodyBytes,
    );

    dynamic decoded;

    if (body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = body;
      }
    }

    if (statusCode >= 200 &&
        statusCode < 300) {
      return decoded;
    }

    String message =
        'Error HTTP $statusCode';

    if (decoded is Map) {
      if (decoded['message'] != null) {
        message =
            decoded['message'].toString();
      } else if (decoded['error'] != null) {
        message =
            decoded['error'].toString();
      }
    } else if (decoded != null) {
      message = decoded.toString();
    }

    throw Exception(message);
  }
}