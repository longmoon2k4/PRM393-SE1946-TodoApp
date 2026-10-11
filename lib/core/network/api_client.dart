import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final FlutterSecureStorage _storage;

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(),
      body: _encode(body),
    );
    return _handle(response);
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(_uri(path), headers: await _headers());
    return _handle(response);
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  Future<void> clearToken() => _storage.delete(key: 'access_token');

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  String? _encode(Map<String, dynamic>? body) =>
      body == null ? null : jsonEncode(body);

  dynamic _handle(http.Response response) {
    final payload = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          payload is Map<String, dynamic> && payload['message'] is String
          ? payload['message'] as String
          : 'Request failed (${response.statusCode})';
      throw ApiException(message, response.statusCode);
    }
    return payload;
  }
}
