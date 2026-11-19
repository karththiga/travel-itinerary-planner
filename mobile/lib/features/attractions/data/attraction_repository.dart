import 'dart:convert';

import '../../../core/network/api_service.dart';
import 'attraction.dart';

class AttractionRepository {
  const AttractionRepository(this._api);

  final ApiService _api;

  Future<List<Attraction>> getAttractions() async {
    final response = await _api.fetchAttractions();

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((json) => Attraction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attractions');
    }
  }
}
