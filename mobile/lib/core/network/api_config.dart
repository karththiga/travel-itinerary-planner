import 'package:flutter/foundation.dart';

const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';
}
