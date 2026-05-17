import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app/app_config.dart';

class ApiClient {
  ApiClient({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await accessToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool withAuth = true}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = await _headers(withAuth: withAuth);
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 401 && withAuth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final newHeaders = await _headers(withAuth: true);
        return _client.get(uri, headers: newHeaders);
      }
    }
    return response;
  }

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = await _headers(withAuth: withAuth);
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 401 && withAuth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final newHeaders = await _headers(withAuth: true);
        return _client.post(
          uri,
          headers: newHeaders,
          body: jsonEncode(body),
        );
      }
    }
    return response;
  }

  Future<bool> _tryRefresh() async {
    final rt = await _storage.read(key: _refreshTokenKey);
    if (rt == null) return false;
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await saveTokens(
          data['access_token'] as String,
          data['refresh_token'] as String,
        );
        return true;
      }
    } catch (_) {}
    await clearTokens();
    return false;
  }
}
