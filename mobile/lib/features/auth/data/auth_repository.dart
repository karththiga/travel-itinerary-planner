import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_service.dart';

class _AuthSession {
  const _AuthSession({required this.token, required this.lifetime});

  final String token;
  final Duration lifetime;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthRepository extends ChangeNotifier {
  AuthRepository(this._api);

  final ApiService _api;
  _AuthSession? _session;
  Timer? _expiry;
  bool _disposed = false;

  bool get signedIn => _session != null;

  Future<void> authenticate({
    required String email,
    required String password,
    required bool signup,
  }) async {
    final response = await _request(
      () => _api.authenticate(email: email, password: password, signup: signup),
    );
    final data = _readJson(response);
    if (response.statusCode != (signup ? 201 : 200)) {
      final message = data?['message'];
      throw AuthException(
        message is String ? message : 'Account service is unavailable.',
      );
    }

    final token = data?['token'];
    final expiresIn = data?['expiresIn'];
    if (token is! String ||
        token.isEmpty ||
        expiresIn is! int ||
        expiresIn <= 0) {
      throw const AuthException('The server returned an invalid session.');
    }
    if (_disposed) return;
    final session = _AuthSession(
      token: token,
      lifetime: Duration(seconds: expiresIn),
    );
    _expiry?.cancel();
    _session = session;
    _expiry = Timer(session.lifetime, _endSession);
    notifyListeners();
  }

  Future<void> logout() async {
    final session = _session;
    if (session == null) return;
    final response = await _request(() => _api.logout(session.token));
    if (response.statusCode != 204) {
      throw const AuthException(
        'Could not end your session. Please try again.',
      );
    }
    if (!_disposed && identical(_session, session)) _endSession();
  }

  void _endSession() {
    _expiry?.cancel();
    _session = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    super.dispose();
  }

  Future<http.Response> _request(Future<http.Response> Function() send) async {
    if (!kDebugMode && !_api.usesHttps) {
      throw const AuthException('Set an HTTPS API URL for this build.');
    }
    try {
      return await send();
    } on TimeoutException {
      throw const AuthException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AuthException('Could not connect to the server.');
    }
  }

  Map<String, dynamic>? _readJson(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : null;
    } on FormatException {
      return null;
    }
  }
}
