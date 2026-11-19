import 'package:flutter/material.dart';

import '../../auth/data/auth_repository.dart';
import '../../preferences/presentation/preference_screen.dart';
import '../data/attraction.dart';
import '../data/attraction_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.attractions,
    required this.onLogout,
  });

  final AttractionRepository attractions;

  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Attraction>> attractions;
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await widget.onLogout();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  void initState() {
    super.initState();
    attractions = widget.attractions.getAttractions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sri Lanka Travel Planner'),
        actions: [
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PreferenceScreen()),
          );
        },
        icon: const Icon(Icons.travel_explore),
        label: const Text('Plan Trip'),
      ),

      body: FutureBuilder<List<Attraction>>(
        future: attractions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attractions found'));
          }

          final attractionList = snapshot.data!;

          return ListView.builder(
            itemCount: attractionList.length,
            itemBuilder: (context, index) {
              final attraction = attractionList[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(attraction.name),
                  subtitle: Text(
                    '${attraction.district} • ${attraction.category}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
