import 'dart:convert';

import '../../../core/network/api_service.dart';
import '../../attractions/data/attraction.dart';

class TripPreferences {
  const TripPreferences({
    required this.interests,
    required this.tripDays,
    required this.budget,
    required this.groupType,
    required this.transport,
  });

  final List<String> interests;
  final int tripDays;
  final double budget;
  final String groupType;
  final String transport;
}

class Recommendation {
  const Recommendation(this.attraction, this.matches, this.discovery);

  final Attraction attraction;
  final List<String> matches;
  final bool discovery;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      Attraction.fromJson(json['attraction'] as Map<String, dynamic>),
      List<String>.from(json['matches'] as List),
      json['discovery'] == true,
    );
  }
}

class TripPlanningRepository {
  const TripPlanningRepository(this._api);

  final ApiService _api;

  Future<List<Recommendation>> recommend(
    TripPreferences preferences, {
    required List<String> excluded,
    required List<String> previous,
  }) async {
    final rows = await _request('recommendations', 'recommendations', {
      'interests': preferences.interests,
      'tripDays': preferences.tripDays,
      'budget': preferences.budget,
      'groupType': preferences.groupType,
      'transport': preferences.transport,
      'excluded': excluded,
      'previous': previous,
    });
    return rows.map(Recommendation.fromJson).toList();
  }

  Future<List<Attraction>> createRoute(List<String> ids) async {
    final rows = await _request('travel-route', 'stops', {
      'attractionIds': ids,
    });
    return rows.map(Attraction.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _request(
    String endpoint,
    String field,
    Map<String, Object> body,
  ) async {
    final response = await _api.planTrip(endpoint, body);
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw TripPlanningException(
        json is Map && json['message'] is String
            ? json['message'] as String
            : 'Trip planning is temporarily unavailable.',
      );
    }
    return List<Map<String, dynamic>>.from(json[field] as List);
  }
}

class TripPlanningException implements Exception {
  const TripPlanningException(this.message);

  final String message;
}
