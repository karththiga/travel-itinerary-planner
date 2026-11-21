import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../../attractions/data/attraction.dart';
import '../../attractions/presentation/attraction_card.dart';
import '../data/trip_planning_repository.dart';
import 'itinerary_preview_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({
    super.key,
    required this.preferences,
    required this.repository,
    required this.bookmarks,
    required this.onToggleSaved,
    required this.onOpen,
    required this.onSaveTrip,
  });

  final TripPreferences preferences;
  final TripPlanningRepository repository;
  final ValueListenable<Set<String>?> bookmarks;
  final ValueChanged<String> onToggleSaved;
  final ValueChanged<Attraction> onOpen;
  final Future<void> Function(TripPreferences, List<Attraction>) onSaveTrip;

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _excluded = <String>{};
  List<Recommendation> _items = [];
  bool _loading = false;
  bool _routing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool regenerate = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repository.recommend(
        widget.preferences,
        excluded: _excluded.toList(),
        previous: regenerate
            ? _items.map((item) => item.attraction.id).toList()
            : [],
      );
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is TripPlanningException
              ? error.message
              : 'Could not load recommendations. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createRoute() async {
    final ids = _items.map((item) => item.attraction.id).toList();
    setState(() => _routing = true);
    try {
      final stops = await widget.repository.createRoute(ids);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ItineraryPreviewScreen(
            preferences: widget.preferences,
            stops: stops,
            onOpen: widget.onOpen,
            onSave: () => widget.onSaveTrip(widget.preferences, stops),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is TripPlanningException
                ? error.message
                : 'Could not create your route. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = widget.preferences;
    final busy = _loading || _routing;
    return Theme(
      data: buildTripPlanningTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Recommended for You',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Text(
                  'Discover attractions selected around your interests, budget and travel duration.',
                  style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final label in [
                      ...preferences.interests,
                      '${preferences.tripDays} ${preferences.tripDays == 1 ? 'Day' : 'Days'}',
                      'LKR ${preferences.budget.toStringAsFixed(2)}',
                    ])
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF292929),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(label),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (busy) const LinearProgressIndicator(),
                if (_error case final message?)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(message),
                    trailing: TextButton(
                      onPressed: busy
                          ? null
                          : () => _load(regenerate: _items.isNotEmpty),
                      child: const Text('Retry'),
                    ),
                  )
                else if (!_loading && _items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No suggestions available. Go back to change your preferences or regenerate suggestions.',
                    ),
                  ),
                for (final item in _items)
                  ValueListenableBuilder(
                    valueListenable: widget.bookmarks,
                    builder: (context, bookmarks, child) => _RecommendationCard(
                      item: item,
                      saved:
                          bookmarks?.contains(item.attraction.bookmarkKey) ??
                          false,
                      onSave: () =>
                          widget.onToggleSaved(item.attraction.bookmarkKey),
                      onOpen: () => widget.onOpen(item.attraction),
                      onRemove: busy
                          ? null
                          : () => setState(() {
                              _excluded.add(item.attraction.id);
                              _items.remove(item);
                            }),
                    ),
                  ),
                if (!_loading && _error == null)
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _load(regenerate: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate suggestions'),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy || _items.isEmpty ? null : _createRoute,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Create My Travel Route'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.saved,
    required this.onSave,
    required this.onOpen,
    required this.onRemove,
  });

  final Recommendation item;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final place = item.attraction;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: theme.colorScheme.surface,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF383838)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AttractionPhoto(place: place),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filled(
                  tooltip: saved ? 'Remove from Saved' : 'Save attraction',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xDD171717),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onSave,
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    place.category,
                    'Entry · ${place.admissionLabel}',
                  ].where((part) => part.isNotEmpty).join('  •  '),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      item.discovery
                          ? Icons.eco_outlined
                          : Icons.auto_awesome_outlined,
                      size: 19,
                      color: item.discovery
                          ? const Color(0xFF70CF98)
                          : exploreOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          'Matches your ${item.matches.join(' and ').toLowerCase()} ${item.matches.length == 1 ? 'interest' : 'interests'}',
                          if (item.discovery) 'Lesser-known destination',
                        ].join(' · '),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: onOpen,
                      child: const Text('View details'),
                    ),
                    TextButton(
                      onPressed: onRemove,
                      child: const Text('Remove suggestion'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
