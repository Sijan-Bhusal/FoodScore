import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/app_config.dart';

class AuthDataSource {
  AuthDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/google');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(body['detail'] as String? ?? 'Google login failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> emailLogin(String email, String password) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(body['detail'] as String? ?? 'Login failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/register');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(body['detail'] as String? ?? 'Registration failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe(String accessToken) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/me');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw AuthException('Failed to fetch user profile');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
    String accessToken, {
    String? displayName,
    String? avatarUrl,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/me');
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    final response = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw AuthException('Failed to update profile');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
