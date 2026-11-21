import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../data/attraction.dart';
import '../data/travel_interest.dart';
import 'attraction_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({
    super.key,
    required this.attractions,
    required this.search,
    required this.focus,
    required this.onRetry,
    required this.onBack,
    required this.category,
    required this.onCategoryChanged,
    required this.onOpen,
  });

  final Future<List<Attraction>> attractions;
  final TextEditingController search;
  final FocusNode focus;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final TravelInterest? category;
  final ValueChanged<TravelInterest?> onCategoryChanged;
  final ValueChanged<Attraction> onOpen;

  static const _filters = {
    null: 'All',
    TravelInterest.nature: 'Nature',
    TravelInterest.history: 'History',
    TravelInterest.beach: 'Beaches',
    TravelInterest.wildlife: 'Wildlife',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: onBack),
        title: const Text(
          'Explore Sri Lanka',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: search,
              focusNode: focus,
              leading: const Icon(Icons.search),
              hintText: 'Search attractions or destinations',
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              trailing: [
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: search.clear,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final filter in _filters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.value),
                      selected: category == filter.key,
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      selectedColor: exploreOrange,
                      labelStyle: const TextStyle(color: Color(0xFF301407)),
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                      onSelected: (_) {
                        focus.unfocus();
                        onCategoryChanged(filter.key);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: attractions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not load attractions.'),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  );
                }
                final places = snapshot.data ?? const <Attraction>[];
                return ValueListenableBuilder(
                  valueListenable: search,
                  builder: (context, input, child) {
                    final query = input.text.trim().toLowerCase();
                    final matches = places
                        .where(
                          (place) =>
                              (category?.matchesCategory(place.category) ??
                                  true) &&
                              [
                                place.name,
                                ...place.aliases,
                                place.location,
                                place.district,
                                place.category,
                              ].any(
                                (value) => value.toLowerCase().contains(query),
                              ),
                        )
                        .toList();
                    if (matches.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty && category == null
                              ? 'No attractions found'
                              : 'No matching attractions',
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final place = matches[index];
                        return AttractionCard(
                          place: place,
                          onOpen: () => onOpen(place),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
