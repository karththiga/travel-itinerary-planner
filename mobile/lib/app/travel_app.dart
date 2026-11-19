import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/network/api_service.dart';
import '../features/attractions/data/attraction_repository.dart';
import '../features/attractions/presentation/home_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    final api = ApiService(_client);
    _auth = AuthRepository(api);
    _attractions = AttractionRepository(api);
  }

  @override
  void dispose() {
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
          title: 'Sri Lanka Travel Planner',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: _auth.signedIn
              ? HomeScreen(attractions: _attractions, onLogout: _auth.logout)
              : AuthScreen(repository: _auth),
        );
      },
    );
  }
}
