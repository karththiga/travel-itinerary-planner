import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../data/attraction.dart';
import '../data/admission.dart';
import '../data/featured_destination.dart';
import '../data/travel_interest.dart';
import 'destination_card.dart';

const _interests = {
  TravelInterest.history: Icons.account_balance_outlined,
  TravelInterest.beach: Icons.beach_access_outlined,
  TravelInterest.nature: Icons.eco_outlined,
  TravelInterest.wildlife: Icons.pets_outlined,
  TravelInterest.culture: Icons.theater_comedy_outlined,
  TravelInterest.adventure: Icons.hiking_outlined,
  TravelInterest.food: Icons.restaurant_outlined,
  TravelInterest.religious: Icons.temple_buddhist_outlined,
};

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.attractions,
    required this.saved,
    required this.onSave,
    required this.onExplore,
    required this.onInterest,
    required this.onPlan,
  });

  final Future<List<Attraction>> attractions;
  final Set<FeaturedDestination> saved;
  final ValueChanged<FeaturedDestination> onSave;
  final ValueChanged<String> onExplore;
  final ValueChanged<TravelInterest> onInterest;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const ValueKey('home-feed'),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              Text(
                'Welcome to ExploreLanka',
                style: theme.textTheme.labelLarge?.copyWith(color: exploreTeal),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover Sri Lanka',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              SearchBar(
                hintText: 'Search destinations, attractions…',
                leading: const Icon(Icons.search),
                readOnly: true,
                onTap: () => onExplore(''),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: const WidgetStatePropertyAll(Colors.white),
              ),
              const SizedBox(height: 18),
              DestinationCard(
                destination: FeaturedDestination.sigiriya,
                saved: saved.contains(FeaturedDestination.sigiriya),
                onSave: () => onSave(FeaturedDestination.sigiriya),
                footer: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your Sri Lankan adventure starts here',
                        style: sectionStyle,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Create a trip that matches your interests and budget.',
                      ),
                      const SizedBox(height: 5),
                      const Text('Sigiriya entry · $sigiriyaAdmission'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onPlan,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(child: Text('Plan My Trip')),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Explore by interest', style: sectionStyle),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(14) > 20
                      ? 2
                      : 4;
                  const gap = 8.0;
                  final width =
                      (constraints.maxWidth - (columns - 1) * gap) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final interest in _interests.entries)
                        SizedBox(
                          width: width,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onInterest(interest.key),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                  horizontal: 3,
                                ),
                                child: Column(
                                  children: [
                                    Icon(interest.value, color: exploreTeal),
                                    const SizedBox(height: 6),
                                    Text(
                                      interest.key.label,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Popular destinations', style: sectionStyle),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < 280
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final place in [
                        FeaturedDestination.ella,
                        FeaturedDestination.galle,
                      ])
                        SizedBox(
                          width: width,
                          child: DestinationCard(
                            destination: place,
                            saved: saved.contains(place),
                            onSave: () => onSave(place),
                            onOpen: () => onExplore(place.label),
                          ),
                        ),
                    ],
                  );
                },
              ),
              FutureBuilder(
                future: attractions,
                builder: (context, snapshot) {
                  final places =
                      (snapshot.data ?? const <Attraction>[])
                          .where((place) => place.popularityScore > 0)
                          .toList()
                        ..sort(
                          (a, b) =>
                              a.popularityScore.compareTo(b.popularityScore),
                        );
                  if (places.length < 3) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text('Lesser-known discoveries', style: sectionStyle),
                      const SizedBox(height: 8),
                      for (final place
                          in places.take(3).take(places.length ~/ 2))
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.place_outlined,
                              color: exploreTeal,
                            ),
                            title: Text(place.name),
                            subtitle: Text(
                              '${place.district}\nEntry · ${place.admissionLabel}',
                            ),
                            onTap: () => onExplore(place.name),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
