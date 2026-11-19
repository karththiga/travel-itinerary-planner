import 'package:flutter/material.dart';
import '../models/attraction.dart';
import '../services/attraction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Attraction>> attractions;

  @override
  void initState() {
    super.initState();
    attractions = AttractionService.getAttractions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sri Lanka Travel Planner'),
      ),
      body: FutureBuilder<List<Attraction>>(
        future: attractions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No attractions found'),
            );
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