import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../data/admission.dart';
import '../data/attraction.dart';
import '../data/travel_interest.dart';
import 'attraction_card.dart';

class InterestPlacesScreen extends StatefulWidget {
  const InterestPlacesScreen({
    super.key,
    required this.interest,
    required this.attractions,
    required this.onRetry,
    required this.onOpen,
  });

  final TravelInterest interest;
  final Future<List<Attraction>> attractions;
  final Future<List<Attraction>> Function() onRetry;
  final ValueChanged<Attraction> onOpen;

  @override
  State<InterestPlacesScreen> createState() => _InterestPlacesScreenState();
}

class _InterestPlacesScreenState extends State<InterestPlacesScreen> {
  late Future<List<Attraction>> _attractions = widget.attractions;

  @override
  Widget build(BuildContext context) {
    final interest = widget.interest;
    return Scaffold(
      appBar: AppBar(title: Text(interest.label)),
      body: SafeArea(
        child: FutureBuilder(
          future: _attractions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final matches = (snapshot.data ?? const <Attraction>[])
                .where((place) => interest.matchesCategory(place.category))
                .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  matches.isEmpty ? 'Suggested place' : 'Places to discover',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (matches.isEmpty)
                  _PlaceCard(
                    name: interest.suggestion,
                    location: interest.location,
                  ),
                for (final place in matches)
                  AttractionCard(
                    place: place,
                    onOpen: () => widget.onOpen(place),
                  ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 12),
                  const Text('The attractions catalog could not be loaded.'),
                  TextButton(
                    onPressed: () =>
                        setState(() => _attractions = widget.onRetry()),
                    child: const Text('Try again'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.name, required this.location});

  final String name;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFD8EEEA),
          foregroundColor: exploreTeal,
          child: Icon(Icons.place_outlined),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          '$location\nEntry · ${curatedAdmission([name]) ?? admissionNotListed}',
        ),
      ),
    );
  }
}
