import 'package:flutter/material.dart';

import '../features/attractions/data/attraction.dart';
import '../features/attractions/data/attraction_repository.dart';
import '../features/attractions/data/bookmark_repository.dart';
import '../features/attractions/data/featured_destination.dart';
import '../features/attractions/data/travel_interest.dart';
import '../features/attractions/presentation/attraction_card.dart';
import '../features/attractions/presentation/attraction_details_screen.dart';
import '../features/attractions/presentation/destination_card.dart';
import '../features/attractions/presentation/explore_screen.dart';
import '../features/attractions/presentation/home_screen.dart';
import '../features/attractions/presentation/interest_places_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/preferences/data/saved_trip_repository.dart';
import '../features/preferences/data/trip_planning_repository.dart';
import '../features/preferences/presentation/itinerary_preview_screen.dart';
import '../features/preferences/presentation/saved_trips_view.dart';
import '../features/preferences/presentation/preference_screen.dart';
import '../features/preferences/presentation/recommendations_screen.dart';

enum _Tab { home, explore, plan, saved, profile }

class SignedInShell extends StatefulWidget {
  const SignedInShell({
    super.key,
    required this.attractions,
    required this.bookmarks,
    required this.auth,
    required this.tripPlanning,
    required this.savedTrips,
  });

  final AttractionRepository attractions;
  final BookmarkRepository bookmarks;
  final AuthRepository auth;
  final TripPlanningRepository tripPlanning;
  final SavedTripRepository savedTrips;

  @override
  State<SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<SignedInShell> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _bookmarks = ValueNotifier<Set<String>?>(null);
  final _pendingBookmarks = <String>{};
  String? _bookmarkError;

  String _featuredKey(FeaturedDestination place) => 'featured:${place.name}';
  TravelInterest? _exploreCategory;
  late Future<List<Attraction>> _attractions;
  _Tab _tab = _Tab.home;
  bool _showTrips = true;

  @override
  void initState() {
    super.initState();
    _attractions = widget.attractions.getAttractions();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _bookmarks.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _select(_Tab tab) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (tab == _Tab.saved && _tab != _Tab.saved) _showTrips = true;
      _tab = tab;
    });
  }

  void _explore(String query) {
    _search.text = query;
    _exploreCategory = null;
    _select(_Tab.explore);
    if (query.isEmpty) _searchFocus.requestFocus();
  }

  void _goHome() => _select(_Tab.home);

  Future<List<Attraction>> _reloadAttractions() {
    final request = widget.attractions.getAttractions();
    setState(() => _attractions = request);
    return request;
  }

  void _openInterest(TravelInterest interest) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => InterestPlacesScreen(
          interest: interest,
          attractions: _attractions,
          onRetry: _reloadAttractions,
          onOpen: _openAttraction,
        ),
      ),
    );
  }

  Future<void> _loadBookmarks() async {
    try {
      final keys = await widget.bookmarks.load();
      if (!mounted) return;
      setState(() => _bookmarks.value = keys);
    } on AuthException catch (error) {
      if (mounted) setState(() => _bookmarkError = error.message);
    }
  }

  Future<void> _toggleSaved(String key) async {
    final keys = _bookmarks.value;
    if (keys == null) {
      if (_bookmarkError != null) {
        _showMessage(_bookmarkError!);
        setState(() => _bookmarkError = null);
        await _loadBookmarks();
      } else {
        _showMessage('Your saved destinations are loading.');
      }
      return;
    }
    if (!_pendingBookmarks.add(key)) return;
    final save = !keys.contains(key);
    try {
      await widget.bookmarks.setSaved(key, save);
      if (!mounted) return;
      final updated = {..._bookmarks.value!};
      if (save) {
        updated.add(key);
      } else {
        updated.remove(key);
      }
      setState(() => _bookmarks.value = updated);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      _pendingBookmarks.remove(key);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openRecommendations(TripPreferences preferences) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RecommendationsScreen(
          preferences: preferences,
          repository: widget.tripPlanning,
          onSaveTrip: widget.savedTrips.save,
          bookmarks: _bookmarks,
          onToggleSaved: _toggleSaved,
          onOpen: _openAttraction,
        ),
      ),
    );
  }

  void _openAttraction(Attraction place) {
    _searchFocus.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ValueListenableBuilder(
          valueListenable: _bookmarks,
          builder: (context, bookmarks, child) => AttractionDetailsScreen(
            place: place,
            saved: bookmarks?.contains(place.bookmarkKey) ?? false,
            onToggleSaved: () => _toggleSaved(place.bookmarkKey),
          ),
        ),
      ),
    );
  }

  void _openSavedTrip(SavedTrip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ItineraryPreviewScreen(
          preferences: trip.preferences,
          stops: trip.stops,
          onOpen: _openAttraction,
        ),
      ),
    );
  }

  Widget _savedContent(Set<FeaturedDestination> featured) {
    if (_bookmarkError != null) {
      return _savedError(_bookmarkError!, () {
        setState(() => _bookmarkError = null);
        _loadBookmarks();
      });
    }
    final keys = _bookmarks.value;
    if (keys == null) return const Center(child: CircularProgressIndicator());
    if (keys.isEmpty) {
      return const Center(
        child: Text('Bookmark a destination to find it here.'),
      );
    }
    return FutureBuilder(
      future: _attractions,
      builder: (context, snapshot) {
        final places = snapshot.data ?? const <Attraction>[];
        final savedPlaces = {
          for (final place in places)
            if (keys.contains(place.bookmarkKey)) place.bookmarkKey: place,
        };
        final needsCatalog = keys.length > featured.length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final place in featured)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DestinationCard(
                  destination: place,
                  saved: true,
                  onSave: () => _toggleSaved(_featuredKey(place)),
                  onOpen: () => _explore(place.label),
                ),
              ),
            for (final place in savedPlaces.values)
              AttractionCard(
                place: place,
                onOpen: () => _openAttraction(place),
              ),
            if (needsCatalog &&
                snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator()),
            if (needsCatalog &&
                snapshot.hasError &&
                snapshot.connectionState == ConnectionState.done)
              _savedError(
                'Could not load the attraction catalog.',
                _reloadAttractions,
              ),
            if (snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError)
              for (final key in keys)
                if (!key.startsWith('featured:') &&
                    !savedPlaces.containsKey(key))
                  ListTile(
                    title: const Text('Attraction unavailable'),
                    trailing: IconButton(
                      tooltip: 'Remove from Saved',
                      icon: const Icon(Icons.bookmark_remove_outlined),
                      onPressed: () => _toggleSaved(key),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _savedError(String message, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = {
      for (final place in FeaturedDestination.values)
        if (_bookmarks.value?.contains(_featuredKey(place)) ?? false) place,
    };
    return PopScope(
      canPop: _tab == _Tab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _tab != _Tab.home) _goHome();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [
            HomeScreen(
              attractions: _attractions,
              saved: featured,
              onSave: (place) => _toggleSaved(_featuredKey(place)),
              onExplore: _explore,
              onInterest: _openInterest,
              onPlan: () => _select(_Tab.plan),
            ),
            ExploreScreen(
              attractions: _attractions,
              search: _search,
              focus: _searchFocus,
              onRetry: _reloadAttractions,
              onBack: _goHome,
              category: _exploreCategory,
              onCategoryChanged: (value) =>
                  setState(() => _exploreCategory = value),
              onOpen: _openAttraction,
            ),
            PreferenceScreen(onBack: _goHome, onSubmit: _openRecommendations),
            Scaffold(
              appBar: AppBar(
                leading: BackButton(onPressed: _goHome),
                title: Text(_showTrips ? 'Saved Trips' : 'Saved Places'),
              ),
              body: _tab != _Tab.saved
                  ? null
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('Trips'),
                                icon: Icon(Icons.route_outlined),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('Places'),
                                icon: Icon(Icons.bookmark_outline),
                              ),
                            ],
                            selected: {_showTrips},
                            onSelectionChanged: (selection) =>
                                setState(() => _showTrips = selection.single),
                          ),
                        ),
                        Expanded(
                          child: _showTrips
                              ? SavedTripsView(
                                  repository: widget.savedTrips,
                                  onOpen: _openSavedTrip,
                                )
                              : _savedContent(featured),
                        ),
                      ],
                    ),
            ),
            ProfileScreen(repository: widget.auth, onBack: _goHome),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (index) => _select(_Tab.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
