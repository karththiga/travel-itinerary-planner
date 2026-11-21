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
    String? fullName,
    String? phoneNumber,
  }) {
    final action = signup ? 'signup' : 'login';
    return _client
        .post(
          Uri.parse('$apiBaseUrl/api/auth/$action'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            if (signup) 'fullName': fullName,
            if (signup) 'phoneNumber': phoneNumber,
          }),
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> accountRequest(
    String token,
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(
      method,
      Uri.parse('$apiBaseUrl/api/auth/me$path'),
    )..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return (() async {
      final response = await _client.send(request);
      return http.Response.fromStream(response);
    })().timeout(const Duration(seconds: 15));
  }

  Future<http.Response> recoverPassword(
    String action,
    Map<String, String> fields,
  ) {
    return _client
        .post(
          Uri.parse('$apiBaseUrl/api/auth/$action'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(fields),
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

  Future<http.Response> planTrip(String endpoint, Map<String, Object> fields) {
    return _client
        .post(
          Uri.parse('$apiBaseUrl/api/$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(fields),
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> fetchAttractions() {
    return _client.get(Uri.parse('$apiBaseUrl/api/attractions'));
  }
}
