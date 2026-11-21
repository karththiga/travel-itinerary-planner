import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_service.dart';

class _AuthSession {
  const _AuthSession({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  Duration get remaining => expiresAt.difference(DateTime.now());
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthRepository extends ChangeNotifier {
  AuthRepository(this._api, this._storage);

  static const _sessionKey = 'explorelanka.session';

  final ApiService _api;
  final FlutterSecureStorage _storage;
  Future<void>? _pendingClear;
  _AuthSession? _session;
  Timer? _expiry;
  bool _disposed = false;

  AccountProfile? _profile;

  AccountProfile get profile => _profile!;

  bool get signedIn => _session != null;

  Future<void> restoreSession() async {
    final String? saved;
    try {
      saved = await _storage.read(key: _sessionKey);
    } on PlatformException {
      throw const AuthException('Could not read your saved sign-in.');
    }
    if (saved == null || _disposed) return;

    final data = _decodeObject(saved);
    final token = data?['token'];
    final timestamp = data?['expiresAt'];
    final expiresAt = timestamp is String ? DateTime.tryParse(timestamp) : null;
    if (token is! String ||
        token.isEmpty ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      await _clearSavedSession();
      return;
    }

    final response = await _request(
      () => _api.accountRequest(token, 'GET', ''),
    );
    if (_disposed) return;
    final session = _AuthSession(token: token, expiresAt: expiresAt);
    if (response.statusCode == 401 || session.remaining <= Duration.zero) {
      await _clearSavedSession();
      return;
    }
    final user = _readJson(response)?['user'];
    if (response.statusCode != 200 ||
        user is! Map<String, dynamic> ||
        user['email'] is! String) {
      throw const AuthException('Could not verify your saved sign-in.');
    }
    _startSession(session, AccountProfile.fromJson(user));
  }

  Future<void> authenticate({
    required String email,
    required String password,
    required bool signup,
    String? fullName,
    String? phoneNumber,
  }) async {
    final response = await _request(
      () => _api.authenticate(
        email: email,
        password: password,
        signup: signup,
        fullName: fullName,
        phoneNumber: phoneNumber,
      ),
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
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
    );
    final user = data?['user'];
    final profile = user is Map<String, dynamic>
        ? AccountProfile.fromJson(user)
        : AccountProfile(email: email);
    await _pendingClear;
    try {
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode({
          'token': session.token,
          'expiresAt': session.expiresAt.toIso8601String(),
        }),
      );
    } on PlatformException {
      throw const AuthException(
        'Could not securely save your sign-in. Please try again.',
      );
    }
    if (!_disposed) _startSession(session, profile);
  }

  void _startSession(_AuthSession session, AccountProfile profile) {
    _expiry?.cancel();
    _profile = profile;
    _session = session;
    _expiry = Timer(session.remaining, _endSession);
    notifyListeners();
  }

  Future<Map<String, dynamic>> accountRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final session = _session;
    const expired = AuthException('Your session expired. Sign in again.');
    if (session == null) throw expired;
    if (session.remaining <= Duration.zero) {
      _endSession();
      throw expired;
    }
    final response = await _request(
      () => _api.accountRequest(session.token, method, path, body: body),
    );
    if (_disposed || !identical(_session, session)) throw expired;
    final data = _readJson(response);
    if (response.statusCode == 401) {
      _endSession();
      throw expired;
    }
    if (response.statusCode == 204) return {};
    if (response.statusCode == 200 && data != null) return data;
    final message = data?['message'];
    throw AuthException(
      message is String ? message : 'Account service is unavailable.',
    );
  }

  Future<AccountProfile> updateProfile(Map<String, dynamic> fields) async {
    final result = await accountRequest('PATCH', '', body: fields);
    final user = result['user'];
    if (user is! Map<String, dynamic>) {
      throw const AuthException('The server returned an invalid profile.');
    }
    return _profile = AccountProfile.fromJson(user);
  }

  Future<void> requestPasswordReset(String email) =>
      _recover('forgot-password', {'email': email}, 202);

  Future<void> resetPassword(String email, String code, String password) =>
      _recover('reset-password', {
        'email': email,
        'code': code,
        'password': password,
      }, 204);

  Future<void> _recover(
    String action,
    Map<String, String> fields,
    int expectedStatus,
  ) async {
    final response = await _request(() => _api.recoverPassword(action, fields));
    if (response.statusCode == expectedStatus) return;
    final message = _readJson(response)?['message'];
    throw AuthException(
      message is String ? message : 'Password recovery is unavailable.',
    );
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
    if (!_disposed && identical(_session, session)) {
      _endSession();
      await _pendingClear;
    }
  }

  void _endSession() {
    _expiry?.cancel();
    _session = null;
    _profile = null;
    _pendingClear = _clearSavedSession();
    notifyListeners();
  }

  Future<void> _clearSavedSession() async {
    try {
      await _storage.delete(key: _sessionKey);
    } on PlatformException {
      // The expired or revoked token still cannot restore a session.
    }
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

  Map<String, dynamic>? _readJson(http.Response response) =>
      _decodeObject(response.body);

  Map<String, dynamic>? _decodeObject(String raw) {
    try {
      final data = jsonDecode(raw);
      return data is Map<String, dynamic> ? data : null;
    } on FormatException {
      return null;
    }
  }
}

class AccountProfile {
  const AccountProfile({
    required this.email,
    this.fullName = '',
    this.phoneNumber = '',
  });

  final String email;
  final String fullName;
  final String phoneNumber;

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
    email: json['email'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
  );
}
