import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/network/api_service.dart';
import '../features/auth/presentation/session_restore_error_screen.dart';
import '../features/attractions/data/attraction_repository.dart';
import '../features/attractions/data/bookmark_repository.dart';
import '../core/theme/explore_lanka_theme.dart';
import '../features/preferences/data/trip_planning_repository.dart';
import '../features/preferences/data/saved_trip_repository.dart';
import 'signed_in_shell.dart';
import 'splash_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_screen.dart';

class TravelApp extends StatefulWidget {
  const TravelApp({super.key, this.client});

  final http.Client? client;

  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> {
  late final http.Client _client;
  late final AuthRepository _auth;
  late final AttractionRepository _attractions;
  late final BookmarkRepository _bookmarks;
  late final TripPlanningRepository _tripPlanning;
  late final SavedTripRepository _savedTrips;

  late final Timer _splashTimer;
  bool _showSplash = true;
  bool _restoringSession = true;
  String? _restoreError;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(SplashScreen.duration, () {
      setState(() => _showSplash = false);
    });
    _client = widget.client ?? http.Client();
    final api = ApiService(_client);
    _auth = AuthRepository(api, const FlutterSecureStorage());
    _attractions = AttractionRepository(api);
    _bookmarks = BookmarkRepository(_auth);
    _tripPlanning = TripPlanningRepository(api);
    _savedTrips = SavedTripRepository(_auth);
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    String? error;
    try {
      await _auth.restoreSession();
    } on AuthException catch (failure) {
      error = failure.message;
    }
    if (!mounted) return;
    setState(() {
      _restoringSession = false;
      _restoreError = error;
    });
  }

  void _retryRestore() {
    setState(() => _restoringSession = true);
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    _splashTimer.cancel();
    _auth.dispose();
    if (widget.client == null) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, child) {
        return MaterialApp(
          key: ValueKey(_auth.signedIn),
          debugShowCheckedModeBanner: false,
          title: exploreLankaName,
          theme: buildExploreLankaTheme(),
          home: _showSplash || _restoringSession
              ? const SplashScreen()
              : _restoreError != null
              ? SessionRestoreErrorScreen(
                  message: _restoreError!,
                  onRetry: _retryRestore,
                )
              : _auth.signedIn
              ? SignedInShell(
                  attractions: _attractions,
                  bookmarks: _bookmarks,
                  auth: _auth,
                  tripPlanning: _tripPlanning,
                  savedTrips: _savedTrips,
                )
              : AuthScreen(repository: _auth),
        );
      },
    );
  }
}
