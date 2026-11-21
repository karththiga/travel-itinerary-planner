import '../../attractions/data/attraction.dart';
import '../../auth/data/auth_repository.dart';
import 'trip_planning_repository.dart';

class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.preferences,
    required this.stops,
  });

  final String id;
  final TripPreferences preferences;
  final List<Attraction> stops;

  factory SavedTrip.fromJson(Map<String, dynamic> json) {
    final preferences = json['preferences'] as Map<String, dynamic>;
    return SavedTrip(
      id: json['id'] as String,
      preferences: TripPreferences(
        interests: List<String>.from(preferences['interests'] as List),
        tripDays: preferences['tripDays'] as int,
        budget: (preferences['budget'] as num).toDouble(),
        groupType: preferences['groupType'] as String,
        transport: preferences['transport'] as String,
      ),
      stops: (json['stops'] as List)
          .map((stop) => Attraction.fromJson(stop as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SavedTripRepository {
  const SavedTripRepository(this._auth);

  final AuthRepository _auth;

  Future<List<SavedTrip>> load() async {
    final payload = await _auth.accountRequest('GET', '/trips');
    return (payload['trips'] as List)
        .map((trip) => SavedTrip.fromJson(trip as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(TripPreferences preferences, List<Attraction> stops) async {
    await _auth.accountRequest(
      'POST',
      '/trips',
      body: {
        'preferences': {
          'interests': preferences.interests,
          'tripDays': preferences.tripDays,
          'budget': preferences.budget,
          'groupType': preferences.groupType,
          'transport': preferences.transport,
        },
        'attractionIds': stops.map((stop) => stop.id).toList(),
      },
    );
  }

  Future<void> remove(String id) async =>
      _auth.accountRequest('DELETE', '/trips/$id');
}
