import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiService {
  const ApiService(this._client);

  final http.Client _client;

  bool get usesHttps => Uri.parse(apiBaseUrl).scheme == 'https';

  Future<http.Response> authenticate({
    required String email,
    required String password,
    required bool signup,
  }) {
    final action = signup ? 'signup' : 'login';
    return _client
        .post(
          Uri.parse('$apiBaseUrl/api/auth/$action'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> logout(String token) {
    return _client
        .post(
          Uri.parse('$apiBaseUrl/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> fetchAttractions() {
    return _client.get(Uri.parse('$apiBaseUrl/api/attractions'));
  }
}
